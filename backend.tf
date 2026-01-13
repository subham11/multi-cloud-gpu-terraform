# Remote State Backend Configuration
# This file configures remote state storage for team collaboration and state locking

# ============================================================================
# AWS Backend Configuration (S3 + DynamoDB)
# ============================================================================
# Uncomment and configure for AWS deployments
# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-dpg-${var.environment}"
#     key            = "infrastructure/compute/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock-dpg"
#     
#     # Enable versioning for state recovery
#     versioning = true
#     
#     # Server-side encryption
#     server_side_encryption_configuration {
#       rule {
#         apply_server_side_encryption_by_default {
#           sse_algorithm = "AES256"
#         }
#       }
#     }
#   }
# }

# ============================================================================
# Azure Backend Configuration (Blob Storage + Lease)
# ============================================================================
# Uncomment and configure for Azure deployments
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "terraform-state-rg"
#     storage_account_name = "terraformstatevmdpg"
#     container_name       = "tfstate"
#     key                  = "infrastructure.compute.tfstate"
#     
#     # Enable encryption
#     use_azuread_auth = true
#   }
# }

# ============================================================================
# GCP Backend Configuration (Cloud Storage + Object Lock)
# ============================================================================
# Uncomment and configure for GCP deployments
# terraform {
#   backend "gcs" {
#     bucket  = "terraform-state-dpg-${var.environment}"
#     prefix  = "infrastructure/compute"
#     
#     # Enable encryption
#     encryption_key = "projects/PROJECT_ID/locations/global/keyRings/terraform/cryptoKeys/state"
#   }
# }

# ============================================================================
# Local Backend (for development/testing only)
# ============================================================================
# Default configuration - DO NOT use in production
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# ============================================================================
# Backend Setup Instructions
# ============================================================================
# 
# 1. AWS Backend Setup:
#    - Create S3 bucket: aws s3 mb s3://terraform-state-dpg-prod --region us-east-1
#    - Enable versioning: aws s3api put-bucket-versioning --bucket terraform-state-dpg-prod --versioning-configuration Status=Enabled
#    - Enable encryption: aws s3api put-bucket-encryption --bucket terraform-state-dpg-prod --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
#    - Create DynamoDB table: aws dynamodb create-table --table-name terraform-state-lock-dpg --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST
#    - Uncomment AWS backend configuration above
#    - Run: terraform init -migrate-state
#
# 2. Azure Backend Setup:
#    - Create resource group: az group create --name terraform-state-rg --location eastus
#    - Create storage account: az storage account create --resource-group terraform-state-rg --name terraformstatevmdpg --sku Standard_LRS --encryption-services blob
#    - Create container: az storage container create --name tfstate --account-name terraformstatevmdpg
#    - Uncomment Azure backend configuration above
#    - Run: terraform init -migrate-state
#
# 3. GCP Backend Setup:
#    - Create bucket: gsutil mb -p PROJECT_ID -l US gs://terraform-state-dpg-prod
#    - Enable versioning: gsutil versioning set on gs://terraform-state-dpg-prod
#    - Enable encryption: gsutil encryption set -k projects/PROJECT_ID/locations/global/keyRings/terraform/cryptoKeys/state gs://terraform-state-dpg-prod
#    - Uncomment GCP backend configuration above
#    - Run: terraform init -migrate-state
#
# 4. Initialize Backend:
#    terraform init -reconfigure
#
# 5. Verify State:
#    terraform state list
#
# ============================================================================
