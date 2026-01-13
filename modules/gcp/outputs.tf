# GCP Outputs

output "instance_group_id" {
  description = "Managed instance group ID"
  value       = try(google_compute_instance_group_manager.gpu[0].id, null)
}

output "load_balancer_ip" {
  description = "Load balancer IP address"
  value       = try(google_compute_global_forwarding_rule.http[0].ip_address, null)
}

output "backend_service_id" {
  description = "Backend service ID"
  value       = try(google_compute_backend_service.default[0].id, null)
}
