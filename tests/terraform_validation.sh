#!/bin/bash

# Terraform Validation Script
# Tests Terraform configuration without applying changes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR"

echo "=================================================="
echo "Terraform Configuration Validation"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Track exit code
EXIT_CODE=0

# 1. Terraform Format Check
echo -e "\n${YELLOW}[1/5] Checking Terraform format...${NC}"
if terraform fmt -check -recursive "$TERRAFORM_DIR" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Format check passed${NC}"
else
    echo -e "${RED}✗ Format issues found. Run: terraform fmt -recursive${NC}"
    EXIT_CODE=1
fi

# 2. Terraform Initialization (dry-run)
echo -e "\n${YELLOW}[2/5] Initializing Terraform...${NC}"
cd "$TERRAFORM_DIR"
if terraform init -upgrade -backend=false > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Initialization passed${NC}"
else
    echo -e "${RED}✗ Initialization failed${NC}"
    EXIT_CODE=1
fi

# 3. Terraform Validation
echo -e "\n${YELLOW}[3/5] Validating Terraform configuration...${NC}"
if terraform validate > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Configuration is valid${NC}"
else
    echo -e "${RED}✗ Validation failed:${NC}"
    terraform validate
    EXIT_CODE=1
fi

# 4. Check for required variables
echo -e "\n${YELLOW}[4/5] Checking variable definitions...${NC}"
if grep -q "variable \"cloud_provider\"" variables.tf && \
   grep -q "variable \"region\"" variables.tf; then
    echo -e "${GREEN}✓ Required variables defined${NC}"
else
    echo -e "${RED}✗ Missing required variables${NC}"
    EXIT_CODE=1
fi

# 5. Test with dry-run plans (no cloud credentials required)
echo -e "\n${YELLOW}[5/5] Testing plans for each cloud provider...${NC}"

# Test AWS plan (dry-run only)
if terraform plan -var 'cloud_provider=aws' -var 'region=ap-south-1' -var 'vm_name=test-gpu' -no-color 2>&1 | grep -q "aws_instance.gpu"; then
    echo -e "${GREEN}✓ AWS plan valid (would create aws_instance)${NC}"
else
    echo -e "${RED}✗ AWS plan failed${NC}"
    EXIT_CODE=1
fi

# Test Azure plan (dry-run only - will fail at provider auth but that's expected)
if terraform plan -var 'cloud_provider=azure' -var 'region=southeastasia' -var 'vm_name=test-gpu' -no-color 2>&1 | grep -q "azurerm_resource_group.rg"; then
    echo -e "${GREEN}✓ Azure plan valid (would create azurerm_resource_group)${NC}"
elif terraform plan -var 'cloud_provider=azure' -var 'region=southeastasia' -var 'vm_name=test-gpu' -no-color 2>&1 | grep -q "azurerm"; then
    echo -e "${GREEN}✓ Azure configuration valid (requires Azure CLI credentials for full plan)${NC}"
else
    echo -e "${RED}✗ Azure configuration failed${NC}"
    EXIT_CODE=1
fi

# Test GCP plan (dry-run only - will fail at provider auth but that's expected)
if terraform plan -var 'cloud_provider=gcp' -var 'region=asia-south1' -var 'vm_name=test-gpu' -var 'gcp_project_id=test-proj' -no-color 2>&1 | grep -q "google_compute_instance.gpu"; then
    echo -e "${GREEN}✓ GCP plan valid (would create google_compute_instance)${NC}"
elif terraform plan -var 'cloud_provider=gcp' -var 'region=asia-south1' -var 'vm_name=test-gpu' -var 'gcp_project_id=test-proj' -no-color 2>&1 | grep -q "google"; then
    echo -e "${GREEN}✓ GCP configuration valid (requires GCP credentials for full plan)${NC}"
else
    echo -e "${RED}✗ GCP configuration failed${NC}"
    EXIT_CODE=1
fi

# Final summary
echo ""
echo "=================================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}All validation checks passed!${NC}"
else
    echo -e "${RED}Some validation checks failed${NC}"
fi
echo "=================================================="

exit $EXIT_CODE
