# Terraform Quick Reference Guide

Quick commands and workflows for daily Terraform operations.

## 🚀 Common Commands

### Initialization

```bash
# Initialize Terraform
terraform init

# Initialize with upgrade
terraform init -upgrade

# Reconfigure backend
terraform init -reconfigure

# Migrate state
terraform init -migrate-state
```

### Planning

```bash
# Basic plan
terraform plan

# Plan with variable file
terraform plan -var-file="terraform.tfvars.dev"

# Save plan to file
terraform plan -var-file="terraform.tfvars.dev" -out=dev.tfplan

# Plan destroy
terraform plan -destroy

# Target specific resource
terraform plan -target=aws_instance.gpu_instance
```

### Applying

```bash
# Apply with confirmation
terraform apply

# Apply with variable file
terraform apply -var-file="terraform.tfvars.dev"

# Apply saved plan
terraform apply "dev.tfplan"

# Auto-approve (use cautiously)
terraform apply -auto-approve

# Target specific resource
terraform apply -target=module.aws
```

### Destroying

```bash
# Destroy with confirmation
terraform destroy

# Destroy with variable file
terraform destroy -var-file="terraform.tfvars.dev"

# Auto-approve destroy (dangerous!)
terraform destroy -auto-approve

# Target specific resource
terraform destroy -target=aws_instance.gpu_instance
```

### State Management

```bash
# List resources
terraform state list

# Show resource details
terraform state show aws_instance.gpu_instance

# Move resource
terraform state mv aws_instance.old aws_instance.new

# Remove resource from state
terraform state rm aws_instance.gpu_instance

# Pull remote state
terraform state pull > backup.tfstate

# Push local state to remote
terraform state push terraform.tfstate

# Refresh state from infrastructure
terraform refresh
```

### Outputs

```bash
# Show all outputs
terraform output

# Show specific output
terraform output instance_public_ip

# Show outputs in JSON
terraform output -json

# Show outputs raw (no quotes)
terraform output -raw instance_public_ip
```

### Validation and Formatting

```bash
# Validate configuration
terraform validate

# Format code
terraform fmt

# Format recursively
terraform fmt -recursive

# Check formatting (CI/CD)
terraform fmt -check
```

### Workspace Management

```bash
# List workspaces
terraform workspace list

# Create workspace
terraform workspace new staging

# Switch workspace
terraform workspace select production

# Delete workspace
terraform workspace delete dev

# Show current workspace
terraform workspace show
```

### Import

```bash
# AWS EC2 instance
terraform import aws_instance.example i-1234567890abcdef0

# Azure VM
terraform import azurerm_linux_virtual_machine.example \
  /subscriptions/SUB_ID/resourceGroups/RG/providers/Microsoft.Compute/virtualMachines/VM_NAME

# GCP instance
terraform import google_compute_instance.example \
  projects/PROJECT/zones/ZONE/instances/INSTANCE
```

### Tainting

```bash
# Taint resource (mark for replacement)
terraform taint aws_instance.gpu_instance

# Untaint resource
terraform untaint aws_instance.gpu_instance
```

## 🔐 Environment Variables

### Cloud Provider Credentials

```bash
# AWS
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Azure
export ARM_CLIENT_ID="app-id"
export ARM_CLIENT_SECRET="password"
export ARM_SUBSCRIPTION_ID="subscription-id"
export ARM_TENANT_ID="tenant-id"

# GCP
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
export GOOGLE_PROJECT="project-id"
```

### Terraform Variables

```bash
# Set individual variables
export TF_VAR_environment="development"
export TF_VAR_region="us-east-1"
export TF_VAR_git_username="username"
export TF_VAR_git_password="token"
```

### Debug Logging

```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Log levels: TRACE, DEBUG, INFO, WARN, ERROR
export TF_LOG=TRACE
```

## 📋 Workflows

### Development Workflow

```bash
# 1. Pull latest code
git pull origin main

# 2. Initialize
terraform init

# 3. Plan changes
terraform plan -var-file="terraform.tfvars.dev"

# 4. Apply changes
terraform apply -var-file="terraform.tfvars.dev"

# 5. Verify
terraform output

# 6. Commit changes
git add .
git commit -m "Updated infrastructure"
git push origin main
```

### Production Deployment

```bash
# 1. Create backup
terraform state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate

# 2. Plan with output file
terraform plan -var-file="terraform.tfvars.prod" -out=prod.tfplan

# 3. Review plan
terraform show prod.tfplan

# 4. Apply plan
terraform apply "prod.tfplan"

# 5. Verify outputs
terraform output -json > outputs.json

# 6. Tag deployment
git tag -a "deploy-prod-$(date +%Y%m%d)" -m "Production deployment"
```

### Environment Switch

```bash
# Development
terraform apply -var-file="terraform.tfvars.dev"

# Staging
terraform apply -var-file="terraform.tfvars.staging"

# Production
terraform apply -var-file="terraform.tfvars.prod"
```

### Rolling Update

```bash
# 1. Taint first instance
terraform taint 'aws_instance.gpu_instance[0]'

# 2. Apply to replace
terraform apply -var-file="terraform.tfvars.prod"

# 3. Verify health
# Check application and load balancer

# 4. Continue with next instance
terraform taint 'aws_instance.gpu_instance[1]'
terraform apply -var-file="terraform.tfvars.prod"
```

## 🐛 Troubleshooting

### State Lock Issues

```bash
# View lock error message for lock ID
# Force unlock (use cautiously)
terraform force-unlock <LOCK_ID>
```

### Backend Issues

```bash
# Reconfigure backend
terraform init -reconfigure

# Migrate to new backend
# 1. Update backend.tf
# 2. Run migration
terraform init -migrate-state
```

### Resource Conflicts

```bash
# Import existing resource
terraform import <resource_type>.<name> <resource_id>

# Or remove from state
terraform state rm <resource_type>.<name>
```

### Configuration Errors

```bash
# Validate syntax
terraform validate

# Check formatting
terraform fmt -check

# View detailed plan
terraform plan -detailed-exitcode
```

## 📊 Cost Management

### Preview Changes

```bash
# Count resources to be created
terraform plan -var-file="terraform.tfvars.dev" | grep "Plan:"

# Example output: Plan: 12 to add, 0 to change, 0 to destroy
```

### Resource Cleanup

```bash
# Destroy dev environment
terraform destroy -var-file="terraform.tfvars.dev" -auto-approve

# Remove specific resources
terraform destroy -target=aws_instance.gpu_instance[0]
```

## 🔍 Inspection

### View Resources

```bash
# List all resources
terraform state list

# Show resource details
terraform state show aws_instance.gpu_instance

# Show in JSON
terraform show -json | jq '.'
```

### View Outputs

```bash
# All outputs
terraform output

# Specific output
terraform output instance_public_ip

# Use in scripts
INSTANCE_IP=$(terraform output -raw instance_public_ip)
curl http://$INSTANCE_IP
```

## 🔄 Graph Visualization

```bash
# Generate dependency graph
terraform graph | dot -Tpng > graph.png

# Generate plan graph
terraform graph -plan=dev.tfplan | dot -Tpng > plan-graph.png

# Requires graphviz: brew install graphviz (macOS)
```

## 📚 Help and Documentation

```bash
# General help
terraform -help

# Command-specific help
terraform plan -help
terraform apply -help

# Provider documentation
terraform providers

# Version information
terraform version
```

## 🚨 Emergency Commands

### Rollback

```bash
# Restore from backup
terraform state push backup.tfstate

# Re-apply previous configuration
git checkout <previous-commit>
terraform apply
```

### Force Unlock

```bash
# Only if process was terminated
terraform force-unlock <LOCK_ID>
```

### Targeted Fix

```bash
# Fix single resource
terraform taint aws_instance.broken_instance
terraform apply -target=aws_instance.broken_instance
```

## 📋 Pre-Flight Checklist

Before running `terraform apply`:

- [ ] Correct environment selected
- [ ] Variable file specified
- [ ] Plan reviewed
- [ ] State backup created (production)
- [ ] Team notified (production)
- [ ] Authentication configured
- [ ] Permissions verified

## 🎯 Quick Commands by Task

### Deploy New Environment

```bash
terraform init
terraform plan -var-file="terraform.tfvars.dev" -out=dev.tfplan
terraform apply "dev.tfplan"
```

### Update Configuration

```bash
terraform plan -var-file="terraform.tfvars.dev"
terraform apply -var-file="terraform.tfvars.dev"
```

### Destroy Environment

```bash
terraform plan -destroy -var-file="terraform.tfvars.dev"
terraform destroy -var-file="terraform.tfvars.dev"
```

### Fix Drift

```bash
terraform refresh
terraform plan
terraform apply
```

### Import Resource

```bash
terraform import <resource_type>.<name> <resource_id>
terraform plan  # Should show no changes
```

---

**Quick Access**: Bookmark this page for instant reference during operations.

**See Also**:
- [PROVISIONING_GUIDE.md](./PROVISIONING_GUIDE.md) - Detailed procedures
- [OPERATIONS_CHECKLIST.md](./OPERATIONS_CHECKLIST.md) - Step-by-step checklists
- [IAM_RBAC_GUIDE.md](./IAM_RBAC_GUIDE.md) - Permissions guide

**Last Updated**: January 2026
