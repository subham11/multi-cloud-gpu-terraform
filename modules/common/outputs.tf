# Common Module Outputs

output "cloud_init_script" {
  description = "Base64 encoded cloud-init script"
  value       = local.nvidia_cuda_init_script
}
