#!/usr/bin/env bash
set -euo pipefail

# Single-click backend + init + instance name prompt
# This script prompts for provider, backend config values, and vm_name, then runs terraform init.

read -rp "Choose provider (aws/azure/gcp): " PROVIDER
case "$PROVIDER" in
  aws|azure|gcp) ;;
  *) echo "Invalid provider"; exit 1 ;;
esac

read -rp "Environment name (dev/staging/prod): " ENV
read -rp "Instance name (vm_name): " VM_NAME

BACKEND_HCL="backends/${PROVIDER}-backend.hcl"

# Collect backend parameters per provider
if [[ "$PROVIDER" == "aws" ]]; then
  read -rp "S3 bucket name: " AWS_BUCKET
  read -rp "Region: " AWS_REGION
  read -rp "DynamoDB table for locks: " AWS_DDB
  read -rp "State key (e.g., network/terraform.tfstate): " AWS_KEY
  cat > "$BACKEND_HCL" <<EOF
bucket         = "$AWS_BUCKET"
key            = "$AWS_KEY"
region         = "$AWS_REGION"
encrypt        = true
dynamodb_table = "$AWS_DDB"
EOF
elif [[ "$PROVIDER" == "azure" ]]; then
  read -rp "Resource group name: " AZ_RG
  read -rp "Storage account name: " AZ_SA
  read -rp "Container name: " AZ_CT
  read -rp "State key (e.g., network/terraform.tfstate): " AZ_KEY
  cat > "$BACKEND_HCL" <<EOF
resource_group_name  = "$AZ_RG"
storage_account_name = "$AZ_SA"
container_name       = "$AZ_CT"
key                  = "$AZ_KEY"
use_azuread_auth     = true
EOF
else
  read -rp "GCS bucket: " GCS_BUCKET
  read -rp "Prefix (e.g., network): " GCS_PREFIX
  read -rp "(Optional) CMEK resource ID or leave blank: " GCS_CMEK
  cat > "$BACKEND_HCL" <<EOF
bucket = "$GCS_BUCKET"
prefix = "$GCS_PREFIX"
EOF
  if [[ -n "$GCS_CMEK" ]]; then
    echo "encryption_key = \"$GCS_CMEK\"" >> "$BACKEND_HCL"
  fi
fi

echo "backend config written to $BACKEND_HCL"

# Write a local tfvars override for vm_name (non-destructive to existing tfvars)
TFVARS_FILE="vm.auto.tfvars"
cat > "$TFVARS_FILE" <<EOF
vm_name     = "$VM_NAME"
environment = "$ENV"
EOF
echo "vm_name and environment captured in $TFVARS_FILE"

# Run terraform init with backend config
terraform init -reconfigure -backend-config="$BACKEND_HCL"

echo "Init complete. Next: terraform plan -var-file=terraform.tfvars.$ENV"
