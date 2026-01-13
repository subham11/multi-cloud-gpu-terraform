# Terraform Operations Checklist

This checklist provides step-by-step procedures for common Terraform operations.

## 📋 Pre-Deployment Checklist

### Before Every Deployment

- [ ] **Authentication configured**
  ```bash
  # AWS
  aws sts get-caller-identity
  
  # Azure
  az account show
  
  # GCP
  gcloud auth list
  ```

- [ ] **Correct environment selected**
  ```bash
  # Verify variable file
  cat terraform.tfvars.dev
  # or
  cat terraform.tfvars.staging
  # or
  cat terraform.tfvars.prod
  ```

- [ ] **Terraform initialized**
  ```bash
  terraform init
  terraform validate
  ```

- [ ] **State backend configured** (for staging/production)
  ```bash
  # Verify backend configuration
  cat backend.tf
  ```

- [ ] **IAM permissions verified**
  ```bash
  # See IAM_RBAC_GUIDE.md for verification commands
  ```

- [ ] **Code review completed**
  ```bash
  git log -1
  git diff main
  ```

- [ ] **Tags configured**
  ```bash
  # Verify tags in tfvars file
  grep -A 10 "tags =" terraform.tfvars.dev
  ```

## 🚀 New Environment Deployment

### Step-by-Step Procedure

#### 1. Initialize Workspace
```bash
# Clone repository
git clone <repo-url>
cd multi-cloud-gpu-terraform

# Initialize Terraform
terraform init
```

#### 2. Configure Remote State (Skip for development)
```bash
# For AWS
# See PROVISIONING_GUIDE.md - AWS S3 Backend Setup

# For Azure  
# See PROVISIONING_GUIDE.md - Azure Blob Storage Backend

# For GCP
# See PROVISIONING_GUIDE.md - GCP Cloud Storage Backend

# Migrate state
terraform init -migrate-state
```

#### 3. Configure Variables
```bash
# Copy appropriate environment file
cp terraform.tfvars.dev terraform.tfvars

# Or create custom configuration
vim terraform.tfvars
```

#### 4. Plan Deployment
```bash
# Generate plan
terraform plan -var-file="terraform.tfvars.dev" -out=dev.tfplan

# Review plan output
terraform show dev.tfplan

# Check resource count
# Expected: ~10-15 resources for single cloud provider
```

#### 5. Review Plan Details
- [ ] Resource counts match expectations
- [ ] Tags are properly configured
- [ ] Security groups have correct rules
- [ ] Network configuration is correct
- [ ] No unexpected deletions or changes
- [ ] Estimated costs are acceptable

#### 6. Apply Configuration
```bash
# Apply with plan file
terraform apply "dev.tfplan"

# Or apply directly
terraform apply -var-file="terraform.tfvars.dev"
```

#### 7. Verify Deployment
```bash
# Check outputs
terraform output

# Verify instance is running
terraform state show <instance_resource>

# Test connectivity (example for AWS)
INSTANCE_IP=$(terraform output -raw instance_public_ip)
curl http://$INSTANCE_IP

# Test load balancer
LB_DNS=$(terraform output -raw load_balancer_dns)
curl http://$LB_DNS
```

#### 8. Document Deployment
```bash
# Save outputs
terraform output -json > outputs.json

# Tag in git
git tag -a "deploy-dev-$(date +%Y%m%d)" -m "Development deployment"
git push origin --tags
```

## 🔄 Update Existing Infrastructure

### Minor Updates (Config Changes)

```bash
# 1. Make changes to variables or configuration
vim terraform.tfvars.dev

# 2. Plan changes
terraform plan -var-file="terraform.tfvars.dev"

# 3. Review changes
# - Look for resources being modified (yellow ~)
# - Ensure no unexpected deletions (red -)

# 4. Apply changes
terraform apply -var-file="terraform.tfvars.dev"

# 5. Verify
terraform output
```

### Major Updates (Resource Replacement)

```bash
# 1. Review what will be replaced
terraform plan -var-file="terraform.tfvars.prod"

# 2. Create backup (production only)
terraform state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate

# 3. Plan replacement
# Look for: -/+ (destroy and create replacement)

# 4. Consider maintenance window
# - Notify users of downtime
# - Schedule during low-traffic period

# 5. Apply changes
terraform apply -var-file="terraform.tfvars.prod"

# 6. Monitor and verify
# - Check application health
# - Monitor logs
# - Verify connectivity
```

### Rolling Updates

```bash
# 1. Taint specific instance for replacement
terraform taint aws_instance.gpu_instance[0]

# 2. Plan replacement
terraform plan -var-file="terraform.tfvars.prod"

# 3. Apply to replace one instance
terraform apply -var-file="terraform.tfvars.prod"

# 4. Verify instance is healthy
# Check load balancer health checks

# 5. Repeat for remaining instances
```

## 🏷️ Resource Tagging Update

### Update Tags Across All Resources

```bash
# 1. Update tags in locals.tf or tfvars
vim terraform.tfvars.dev

# Add/modify in tags section:
tags = {
  Environment = "development"
  CostCenter  = "engineering"
  Owner       = "devops-team"
  NewTag      = "new-value"
}

# 2. Plan changes
terraform plan -var-file="terraform.tfvars.dev"

# 3. Apply changes
terraform apply -var-file="terraform.tfvars.dev"
```

## 🔍 Troubleshooting Operations

### State is Locked

```bash
# 1. Check who has the lock
# Look at lock info in error message

# 2. Wait for operation to complete
# If other team member is running terraform

# 3. Force unlock (if process was killed)
terraform force-unlock <LOCK_ID>

# 4. Verify state is consistent
terraform plan
```

### State Drift Detection

```bash
# 1. Refresh state from infrastructure
terraform refresh -var-file="terraform.tfvars.prod"

# 2. Compare state to configuration
terraform plan -var-file="terraform.tfvars.prod"

# 3. Fix drift
# Option A: Update configuration to match reality
vim main.tf

# Option B: Update infrastructure to match configuration
terraform apply -var-file="terraform.tfvars.prod"

# Option C: Import resources that were created outside Terraform
terraform import <resource_type>.<name> <resource_id>
```

### Resource Import

```bash
# 1. Add resource to configuration
vim main.tf

# 2. Import existing resource
# AWS example
terraform import aws_instance.gpu_instance i-1234567890abcdef0

# Azure example
terraform import azurerm_linux_virtual_machine.gpu_vm \
  /subscriptions/SUB_ID/resourceGroups/RG/providers/Microsoft.Compute/virtualMachines/VM_NAME

# GCP example
terraform import google_compute_instance.gpu_instance projects/PROJECT/zones/ZONE/instances/INSTANCE

# 3. Verify import
terraform plan
# Should show no changes if import was successful
```

## 🗑️ Decommission Environment

### Development Environment

```bash
# 1. Notify team
echo "Destroying dev environment"

# 2. Preview destruction
terraform plan -destroy -var-file="terraform.tfvars.dev"

# 3. Destroy resources
terraform destroy -var-file="terraform.tfvars.dev"

# 4. Verify all resources removed
terraform state list
# Should return empty
```

### Staging/Production Environment

```bash
# 1. Create backup
terraform state pull > backup-pre-destroy-$(date +%Y%m%d).tfstate

# 2. Document current state
terraform output -json > outputs-pre-destroy.json

# 3. Export data if needed
# Backup databases, configuration, etc.

# 4. Remove lifecycle protection
# Edit resources with prevent_destroy = true
vim modules/aws/compute.tf
# Change: prevent_destroy = false

# 5. Apply to remove protection
terraform apply -var-file="terraform.tfvars.prod"

# 6. Preview destruction
terraform plan -destroy -var-file="terraform.tfvars.prod"

# 7. Destroy resources
terraform destroy -var-file="terraform.tfvars.prod"

# 8. Clean up state storage
# AWS: Delete S3 bucket and DynamoDB table
# Azure: Delete storage account
# GCP: Delete Cloud Storage bucket
```

## 📊 Regular Maintenance Tasks

### Weekly Tasks

- [ ] Review state for drift
  ```bash
  terraform plan -var-file="terraform.tfvars.prod"
  ```

- [ ] Check for Terraform updates
  ```bash
  terraform version
  # Compare with latest: https://www.terraform.io/downloads
  ```

- [ ] Review resource tags
  ```bash
  # AWS
  aws ec2 describe-instances --query 'Reservations[*].Instances[*].Tags'
  
  # Azure
  az resource list --tag Project=digital-public-goods
  
  # GCP
  gcloud compute instances list --format="table(name,labels)"
  ```

### Monthly Tasks

- [ ] Audit IAM permissions
  ```bash
  # See IAM_RBAC_GUIDE.md
  ```

- [ ] Review and update modules
  ```bash
  # Check for module updates
  terraform init -upgrade
  ```

- [ ] Cost analysis
  ```bash
  # Review cloud provider billing dashboard
  # Compare against estimates in PROVISIONING_GUIDE.md
  ```

- [ ] State file cleanup
  ```bash
  # Remove unused state files
  terraform state list
  # Remove obsolete resources
  terraform state rm <resource>
  ```

### Quarterly Tasks

- [ ] Rotate credentials
  ```bash
  # Rotate IAM keys, service principals, service accounts
  # See IAM_RBAC_GUIDE.md
  ```

- [ ] Update documentation
  ```bash
  git log --since="3 months ago" -- "*.md"
  # Review and update guides as needed
  ```

- [ ] Disaster recovery test
  ```bash
  # Test state recovery from backup
  terraform state push backup.tfstate
  ```

## 🚨 Emergency Procedures

### Critical Infrastructure Issue

```bash
# 1. Assess situation
terraform state show <affected_resource>

# 2. Create backup
terraform state pull > emergency-backup.tfstate

# 3. Taint and replace resource
terraform taint <resource>
terraform apply -var-file="terraform.tfvars.prod"

# 4. Monitor replacement
# Check logs and health checks
```

### State File Corruption

```bash
# 1. Recover from backup
# AWS S3: Download previous version
# Azure: Restore from blob snapshots  
# GCP: List and download previous version

# 2. Restore state
terraform state push backup.tfstate

# 3. Verify state
terraform plan
```

### Accidental Resource Deletion

```bash
# 1. Don't panic - check state backup
ls -la terraform.tfstate.backup

# 2. Restore from backup
cp terraform.tfstate.backup terraform.tfstate

# 3. Re-apply configuration
terraform apply -var-file="terraform.tfvars.prod"

# 4. Or recreate from configuration
# If resources were deleted in cloud but not in state:
terraform refresh
terraform apply
```

## 📝 Change Management Template

### Change Request Form

```markdown
# Infrastructure Change Request

## Change Details
- **Date**: YYYY-MM-DD
- **Environment**: [Development/Staging/Production]
- **Requestor**: [Name]
- **Reviewer**: [Name]

## Description
[Describe what changes are being made and why]

## Resources Affected
- [ ] Compute instances
- [ ] Network configuration
- [ ] Security groups
- [ ] Load balancers
- [ ] Other: __________

## Risk Assessment
- **Risk Level**: [Low/Medium/High]
- **Estimated Downtime**: [None/Minutes/Hours]
- **Rollback Plan**: [Describe rollback procedure]

## Pre-Change Checklist
- [ ] Terraform plan reviewed
- [ ] State backup created
- [ ] Team notified
- [ ] Maintenance window scheduled (if needed)
- [ ] Monitoring prepared

## Change Procedure
```bash
# Commands to execute
terraform plan -var-file="terraform.tfvars.prod"
terraform apply -var-file="terraform.tfvars.prod"
```

## Post-Change Verification
- [ ] Resources healthy
- [ ] Application functional
- [ ] Monitoring active
- [ ] Documentation updated

## Rollback Procedure
```bash
# If changes need to be reverted
terraform state push backup.tfstate
terraform apply -var-file="terraform.tfvars.prod"
```
```

## 🎓 Training Checklist

### New Team Member Onboarding

- [ ] Install required tools
- [ ] Configure cloud provider access
- [ ] Clone repository
- [ ] Review documentation
  - [ ] TERRAFORM_ARCHITECTURE.md
  - [ ] PROVISIONING_GUIDE.md
  - [ ] IAM_RBAC_GUIDE.md
  - [ ] OPERATIONS_CHECKLIST.md (this document)
- [ ] Deploy development environment
- [ ] Make test changes
- [ ] Practice emergency procedures
- [ ] Shadow experienced engineer

---

**Last Updated**: January 2026  
**Maintained By**: DevOps Team  
**Review Schedule**: Monthly
