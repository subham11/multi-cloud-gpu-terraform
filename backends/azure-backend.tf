# ============================================================================
# Azure Remote Backend Configuration (Blob Storage + Lease Locking)
# Template backend block (commented). Use terraform init -backend-config.
# ============================================================================

/*
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateaccount123"
    container_name       = "tfstate"
    key                  = "multi-cloud-gpu/terraform.tfstate"
    use_azuread_auth     = true
  }
}
*/

# Setup (run once)
# 1) Create RG:
#    az group create --name rg-terraform-state --location eastus
# 2) Create storage account:
#    az storage account create --name tfstateaccount123 --resource-group rg-terraform-state --sku Standard_LRS --encryption-services blob
# 3) Create container:
#    az storage container create --name tfstate --account-name tfstateaccount123
# 4) Enable soft delete/versioning if required
# 5) Run init with backend config:
#    terraform init -reconfigure -backend-config=backends/azure-backend.hcl

# Backend config file example (backends/azure-backend.hcl):
# resource_group_name  = "rg-terraform-state"
# storage_account_name = "tfstateaccount123"
# container_name       = "tfstate"
# key                  = "multi-cloud-gpu/terraform.tfstate"
# use_azuread_auth     = true

# Note: Keep only one active backend configuration when running terraform init.
