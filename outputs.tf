# Multi-Cloud GPU Infrastructure - Outputs
# Consolidated outputs from all cloud providers

# ============================================================================
# AWS OUTPUTS
# ============================================================================

output "aws_instance_id" {
  description = "AWS EC2 instance ID"
  value       = var.cloud_provider == "aws" ? module.aws[0].instance_id : null
}

output "aws_instance_public_ip" {
  description = "AWS EC2 public IP address"
  value       = var.cloud_provider == "aws" ? module.aws[0].instance_public_ip : null
}

output "aws_load_balancer_dns" {
  description = "AWS Application Load Balancer DNS name"
  value       = var.cloud_provider == "aws" ? module.aws[0].load_balancer_dns : null
}

output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = var.cloud_provider == "aws" ? module.aws[0].vpc_id : null
}

# ============================================================================
# AZURE OUTPUTS
# ============================================================================

output "azure_resource_group_name" {
  description = "Azure resource group name"
  value       = var.cloud_provider == "azure" ? module.azure[0].resource_group_name : null
}

output "azure_vm_id" {
  description = "Azure virtual machine ID"
  value       = var.cloud_provider == "azure" ? module.azure[0].vm_id : null
}

output "azure_load_balancer_ip" {
  description = "Azure load balancer public IP"
  value       = var.cloud_provider == "azure" ? module.azure[0].load_balancer_ip : null
}

output "azure_vnet_id" {
  description = "Azure virtual network ID"
  value       = var.cloud_provider == "azure" ? module.azure[0].vnet_id : null
}

# ============================================================================
# GCP OUTPUTS
# ============================================================================

output "gcp_instance_group_id" {
  description = "GCP managed instance group ID"
  value       = var.cloud_provider == "gcp" ? module.gcp[0].instance_group_id : null
}

output "gcp_load_balancer_ip" {
  description = "GCP load balancer IP address"
  value       = var.cloud_provider == "gcp" ? module.gcp[0].load_balancer_ip : null
}

output "gcp_backend_service_id" {
  description = "GCP backend service ID"
  value       = var.cloud_provider == "gcp" ? module.gcp[0].backend_service_id : null
}

# ============================================================================
# DEPLOYMENT INFORMATION
# ============================================================================

output "deployment_info" {
  description = "Deployment information and access details"
  value = {
    cloud_provider = var.cloud_provider
    region         = var.region
    vm_name        = var.vm_name

    applications = {
      oan_ui_service = {
        port   = 5000
        path   = "/health"
        access = "via load balancer on port 80/443"
      }
      agri_help = {
        port   = 3000
        path   = "/health"
        access = "direct instance access"
      }
      jenkins = {
        port        = 8080
        credentials = "admin/admin123"
        access      = "direct instance access"
      }
    }

    access_urls = {
      http = (
        var.cloud_provider == "aws" ? "http://${try(module.aws[0].load_balancer_dns, "N/A")}" :
        var.cloud_provider == "azure" ? "http://${try(module.azure[0].load_balancer_ip, "N/A")}" :
        var.cloud_provider == "gcp" ? "http://${try(module.gcp[0].load_balancer_ip, "N/A")}" : "N/A"
      )

      jenkins = (
        var.cloud_provider == "aws" ? "http://${try(module.aws[0].instance_public_ip, "N/A")}:8080" :
        "Check instance IP for direct access"
      )
    }
  }
}
