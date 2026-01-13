# ============================================================================
# AWS VPC and Networking Resources
# Implements multi-tier network architecture with public, private, and
# database subnets across multiple availability zones
# ============================================================================

# ============================================================================
# VPC Configuration
# ============================================================================

resource "aws_vpc" "main" {
  count                = 1
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-vpc"
      Tier = "network"
    }
  )
}

# VPC Flow Logs for network monitoring and compliance
resource "aws_flow_log" "main" {
  count                   = var.enable_flow_logs ? 1 : 0
  iam_role_arn            = aws_iam_role.vpc_flow_logs[0].arn
  log_destination         = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type            = var.flow_logs_traffic_type
  vpc_id                  = aws_vpc.main[0].id
  log_destination_type    = "cloud-watch-logs"
  log_format              = "${var.flow_logs_format}"
  max_aggregation_interval = 60

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-vpc-flow-logs"
      Tier = "monitoring"
    }
  )

  depends_on = [aws_iam_role_policy.vpc_flow_logs]
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc/flowlogs/${var.vm_name}"
  retention_in_days = var.flow_logs_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-flow-logs"
      Tier = "monitoring"
    }
  )
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.vm_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-vpc-flow-logs-role"
      Tier = "security"
    }
  )
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.vm_name}-vpc-flow-logs-policy"
  role  = aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

# ============================================================================
# Public Subnets (Tier 1)
# ============================================================================

resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = each.value.cidr
  availability_zone       = "${local.effective_region}${each.value.az}"
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-public-subnet-${each.value.az}"
      Tier = "public"
    }
  )
}

# ============================================================================
# Private Subnets (Tier 2)
# ============================================================================

resource "aws_subnet" "private" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = each.value.cidr
  availability_zone = "${local.effective_region}${each.value.az}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-private-subnet-${each.value.az}"
      Tier = "private"
    }
  )
}

# ============================================================================
# Database Subnets (Tier 3)
# ============================================================================

resource "aws_subnet" "database" {
  for_each          = var.database_subnets
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = each.value.cidr
  availability_zone = "${local.effective_region}${each.value.az}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-database-subnet-${each.value.az}"
      Tier = "database"
    }
  )
}

# ============================================================================
# Internet Gateway
# ============================================================================

resource "aws_internet_gateway" "main" {
  count  = 1
  vpc_id = aws_vpc.main[0].id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-igw"
      Tier = "network"
    }
  )
}

# ============================================================================
# Elastic IPs for NAT Gateways
# ============================================================================

resource "aws_eip" "nat" {
  for_each = var.enable_nat_gateway ? var.public_subnets : {}
  domain   = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-eip-nat-${each.value.az}"
      Tier = "network"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ============================================================================
# NAT Gateways for Private Subnets
# ============================================================================

resource "aws_nat_gateway" "main" {
  for_each      = var.enable_nat_gateway ? var.public_subnets : {}
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-nat-${each.value.az}"
      Tier = "network"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ============================================================================
# Public Route Table
# ============================================================================

resource "aws_route_table" "public" {
  count  = 1
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main[0].id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-public-rt"
      Tier = "network"
    }
  )
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

# ============================================================================
# Private Route Tables (one per AZ for NAT Gateway)
# ============================================================================

resource "aws_route_table" "private" {
  for_each = var.private_subnets
  vpc_id   = aws_vpc.main[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.enable_nat_gateway ? aws_nat_gateway.main[each.key].id : null
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-private-rt-${each.value.az}"
      Tier = "network"
    }
  )
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# ============================================================================
# Database Route Table
# ============================================================================

resource "aws_route_table" "database" {
  count  = var.enable_database_subnet ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-database-rt"
      Tier = "network"
    }
  )
}

# Database Route Table Associations
resource "aws_route_table_association" "database" {
  for_each       = aws_subnet.database
  subnet_id      = each.value.id
  route_table_id = aws_route_table.database[0].id
}

# ============================================================================
# Network ACLs (NACLs) for additional layer of security
# ============================================================================

# Public Subnet NACL
resource "aws_network_acl" "public" {
  count     = var.enable_nacl ? 1 : 0
  vpc_id    = aws_vpc.main[0].id
  subnet_ids = [for s in aws_subnet.public : s.id]

  # Inbound Rules
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound Rules
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-public-nacl"
      Tier = "security"
    }
  )
}

# Private Subnet NACL
resource "aws_network_acl" "private" {
  count     = var.enable_nacl ? 1 : 0
  vpc_id    = aws_vpc.main[0].id
  subnet_ids = [for s in aws_subnet.private : s.id]

  # Inbound Rules
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound Rules
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-private-nacl"
      Tier = "security"
    }
  )
}

# Database Subnet NACL
resource "aws_network_acl" "database" {
  count     = var.enable_nacl && var.enable_database_subnet ? 1 : 0
  vpc_id    = aws_vpc.main[0].id
  subnet_ids = [for s in aws_subnet.database : s.id]

  # Inbound Rules - Allow from VPC and private subnets only
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 3306
    to_port    = 3306
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 5432
    to_port    = 5432
  }

  # Outbound Rules
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-database-nacl"
      Tier = "security"
    }
  )
}

# ============================================================================
# VPC Endpoints for AWS Services (to avoid internet route)
# ============================================================================

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_vpc_endpoints ? 1 : 0
  vpc_id            = aws_vpc.main[0].id
  service_name      = "com.amazonaws.${local.effective_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(
    [aws_route_table.public[0].id],
    values(aws_route_table.private)[*].id
  )

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-s3-endpoint"
      Tier = "network"
    }
  )
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  count             = var.enable_vpc_endpoints ? 1 : 0
  vpc_id            = aws_vpc.main[0].id
  service_name      = "com.amazonaws.${local.effective_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(
    [aws_route_table.public[0].id],
    values(aws_route_table.private)[*].id
  )

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-dynamodb-endpoint"
      Tier = "network"
    }
  )
}

# ============================================================================
# Route 53 Private Hosted Zone for DNS
# ============================================================================

resource "aws_route53_zone" "private" {
  count = var.enable_private_hosted_zone ? 1 : 0
  name  = var.private_hosted_zone_name

  vpc {
    vpc_id = aws_vpc.main[0].id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vm_name}-private-zone"
      Tier = "dns"
    }
  )
}
