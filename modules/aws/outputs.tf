# ============================================================================
# AWS Outputs - Infrastructure identifiers and connection details
# ============================================================================

# ============================================================================
# Compute Outputs
# ============================================================================

output "instance_id" {
  description = "ID of the GPU instance"
  value       = try(aws_instance.gpu[0].id, null)
}

output "instance_public_ip" {
  description = "Public IP of the GPU instance"
  value       = try(aws_instance.gpu[0].public_ip, null)
}

output "instance_private_ip" {
  description = "Private IP of the GPU instance"
  value       = try(aws_instance.gpu[0].private_ip, null)
}

# ============================================================================
# Load Balancer Outputs
# ============================================================================

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = try(aws_lb.main[0].dns_name, null)
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = try(aws_lb.main[0].arn, null)
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = try(aws_lb.main[0].zone_id, null)
}

# ============================================================================
# VPC and Network Outputs
# ============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = try(aws_vpc.main[0].id, null)
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = try(aws_vpc.main[0].cidr_block, null)
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [for s in aws_subnet.private : s.id]
}

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = [for s in aws_subnet.database : s.id]
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = try(aws_internet_gateway.main[0].id, null)
}

# ============================================================================
# NAT Gateway Outputs
# ============================================================================

output "nat_gateway_ids" {
  description = "Map of NAT Gateway IDs by subnet"
  value       = { for k, v in aws_nat_gateway.main : k => v.id }
}

output "nat_gateway_ips" {
  description = "Map of Elastic IPs for NAT Gateways"
  value       = { for k, v in aws_eip.nat : k => v.public_ip }
}

# ============================================================================
# Route Table Outputs
# ============================================================================

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = try(aws_route_table.public[0].id, null)
}

output "private_route_table_ids" {
  description = "Map of private route table IDs by AZ"
  value       = { for k, v in aws_route_table.private : k => v.id }
}

output "database_route_table_id" {
  description = "ID of the database route table"
  value       = try(aws_route_table.database[0].id, null)
}

# ============================================================================
# Network ACL Outputs
# ============================================================================

output "public_nacl_id" {
  description = "ID of the public network ACL"
  value       = try(aws_network_acl.public[0].id, null)
}

output "private_nacl_id" {
  description = "ID of the private network ACL"
  value       = try(aws_network_acl.private[0].id, null)
}

output "database_nacl_id" {
  description = "ID of the database network ACL"
  value       = try(aws_network_acl.database[0].id, null)
}

# ============================================================================
# VPC Endpoint Outputs
# ============================================================================

output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}

output "dynamodb_endpoint_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = try(aws_vpc_endpoint.dynamodb[0].id, null)
}

# ============================================================================
# DNS Outputs
# ============================================================================

output "private_hosted_zone_id" {
  description = "ID of the Route53 private hosted zone"
  value       = try(aws_route53_zone.private[0].zone_id, null)
}

output "private_hosted_zone_name" {
  description = "Name of the Route53 private hosted zone"
  value       = try(aws_route53_zone.private[0].name, null)
}

# ============================================================================
# Flow Logs Outputs
# ============================================================================

output "vpc_flow_logs_group" {
  description = "CloudWatch Log Group for VPC Flow Logs"
  value       = try(aws_cloudwatch_log_group.vpc_flow_logs[0].name, null)
}

output "vpc_flow_logs_iam_role_arn" {
  description = "ARN of IAM role for VPC Flow Logs"
  value       = try(aws_iam_role.vpc_flow_logs[0].arn, null)
}

# ============================================================================
# Summary Outputs
# ============================================================================

output "network_summary" {
  description = "Summary of network configuration"
  value = {
    vpc_id              = try(aws_vpc.main[0].id, null)
    vpc_cidr            = try(aws_vpc.main[0].cidr_block, null)
    public_subnets      = length(aws_subnet.public)
    private_subnets     = length(aws_subnet.private)
    database_subnets    = length(aws_subnet.database)
    nat_gateways        = length(aws_nat_gateway.main)
    security_tier_count = 3
  }
}
