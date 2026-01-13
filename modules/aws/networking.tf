# AWS VPC and Networking Resources

resource "aws_vpc" "main" {
  count                = 1
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.vm_name}-vpc"
  }
}

resource "aws_subnet" "public_a" {
  count                   = 1
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${local.effective_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vm_name}-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
  count                   = 1
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${local.effective_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vm_name}-subnet-b"
  }
}

resource "aws_internet_gateway" "main" {
  count  = 1
  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "${var.vm_name}-igw"
  }
}

resource "aws_route_table" "main" {
  count  = 1
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = {
    Name = "${var.vm_name}-rt"
  }
}

resource "aws_route_table_association" "a" {
  count          = 1
  subnet_id      = aws_subnet.public_a[0].id
  route_table_id = aws_route_table.main[0].id
}

resource "aws_route_table_association" "b" {
  count          = 1
  subnet_id      = aws_subnet.public_b[0].id
  route_table_id = aws_route_table.main[0].id
}
