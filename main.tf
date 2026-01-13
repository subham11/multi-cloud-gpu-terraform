# Multi-Cloud GPU Infrastructure - Main Configuration
# This file orchestrates the deployment across AWS, Azure, and GCP

# ============================================================================
# COMMON MODULE - Cloud-Init Scripts
# ============================================================================

module "common" {
  source = "./modules/common"

  git_username      = var.git_username
  git_password      = var.git_password
  setup_script_path = "../../scripts/full-setup.sh"
}

# ============================================================================
# AWS MODULE
# ============================================================================

module "aws" {
  source = "./modules/aws"
  count  = var.cloud_provider == "aws" ? 1 : 0

  vm_name          = var.vm_name
  region           = var.region
  instance_type    = "g5.4xlarge"
  user_data_script = module.common.cloud_init_script
  git_username     = var.git_username
  git_password     = var.git_password
}

# ============================================================================
# AZURE MODULE
# ============================================================================

module "azure" {
  source = "./modules/azure"
  count  = var.cloud_provider == "azure" ? 1 : 0

  vm_name          = var.vm_name
  region           = var.region
  vm_size          = "Standard_NV36ads_A10_v5"
  user_data_script = module.common.cloud_init_script
  ssh_public_key   = var.azure_ssh_public_key != null ? var.azure_ssh_public_key : "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3F... replace-with-your-key"
}

# ============================================================================
# GCP MODULE
# ============================================================================

module "gcp" {
  source = "./modules/gcp"
  count  = var.cloud_provider == "gcp" ? 1 : 0

  vm_name          = var.vm_name
  region           = var.region
  project_id       = var.gcp_project_id
  machine_type     = "g2-standard-16"
  gpu_type         = "nvidia-l4"
  gpu_count        = 1
  user_data_script = module.common.cloud_init_script
}
