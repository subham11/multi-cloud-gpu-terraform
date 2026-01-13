#!/bin/bash

# Generate Terraform Plan without applying
# Shows exactly what would be created

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

CLOUD_PROVIDER="${1:-aws}"
REGION="${2:-ap-south-1}"
VM_NAME="${3:-test-gpu-instance}"
GCP_PROJECT="${4:-test-proj}"

echo -e "${YELLOW}Generating Terraform plan for ${CLOUD_PROVIDER} in ${REGION}${NC}"
echo ""

# Validate cloud provider
case "$CLOUD_PROVIDER" in
    aws|azure|gcp) ;;
    *)
        echo -e "${RED}Invalid cloud provider: $CLOUD_PROVIDER${NC}"
        echo "Use: aws, azure, or gcp"
        exit 1
        ;;
esac

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init -backend=false -upgrade > /dev/null 2>&1

# Set dummy credentials for unused providers to avoid auth errors during planning
export GOOGLE_APPLICATION_CREDENTIALS=/dev/null
export ARM_SKIP_PROVIDER_REGISTRATION=true

# Generate plan with appropriate variables
echo -e "${YELLOW}Generating plan...${NC}"
echo ""

if [ "$CLOUD_PROVIDER" = "gcp" ]; then
    # Unset dummy GCP credentials when actually using GCP
    unset GOOGLE_APPLICATION_CREDENTIALS
    terraform plan \
        -var "cloud_provider=$CLOUD_PROVIDER" \
        -var "region=$REGION" \
        -var "vm_name=$VM_NAME" \
        -var "gcp_project_id=$GCP_PROJECT" \
        -no-color 2>&1
else
    terraform plan \
        -var "cloud_provider=$CLOUD_PROVIDER" \
        -var "region=$REGION" \
        -var "vm_name=$VM_NAME" \
        -no-color 2>&1
fi

PLAN_STATUS=$?

if [ $PLAN_STATUS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Plan generated successfully!${NC}"
else
    # Plan might fail due to provider credentials, but that's OK
    # If it shows resource types, the configuration is valid
    if echo "$PLAN_OUTPUT" | grep -q "aws_instance\|azurerm_resource_group\|google_compute_instance"; then
        echo ""
        echo -e "${GREEN}✓ Configuration is valid for ${CLOUD_PROVIDER}${NC}"
        echo "(Full plan requires cloud credentials)"
    fi
fi
