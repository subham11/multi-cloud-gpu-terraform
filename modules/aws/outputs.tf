# AWS Outputs

output "instance_id" {
  description = "ID of the GPU instance"
  value       = try(aws_instance.gpu[0].id, null)
}

output "instance_public_ip" {
  description = "Public IP of the GPU instance"
  value       = try(aws_instance.gpu[0].public_ip, null)
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = try(aws_lb.main[0].dns_name, null)
}

output "vpc_id" {
  description = "VPC ID"
  value       = try(aws_vpc.main[0].id, null)
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = [for s in concat(aws_subnet.public_a, aws_subnet.public_b) : s.id]
}
