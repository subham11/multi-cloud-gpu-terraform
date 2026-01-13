# Infrastructure Provisioning and Management Guide

This guide provides instructions for provisioning, managing, and destroying Terraform infrastructure across multiple environments.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Environment Configuration](#environment-configuration)
4. [Provisioning Resources](#provisioning-resources)
5. [Managing Infrastructure](#managing-infrastructure)
6. [Destroying Resources](#destroying-resources)
7. [State Management](#state-management)
8. [Troubleshooting](#troubleshooting)

## 🔧 Prerequisites

### Required Tools

```bash
# Terraform (>= 1.5.0)
terraform version

# Cloud CLI tools
aws --version      # AWS CLI (for AWS)
az version         # Azure CLI (for Azure)
gcloud version     # Google Cloud SDK (for GCP)

# Git (for version control)
git --version
```

### Cloud Authentication

**AWS**
```bash
# Configure AWS credentials
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

**Azure**
```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "SUBSCRIPTION_ID"

# Or use service principal
export ARM_CLIENT_ID="APP_ID"
export ARM_CLIENT_SECRET="PASSWORD"
export ARM_SUBSCRIPTION_ID="SUBSCRIPTION_ID"
export ARM_TENANT_ID="TENANT_ID"
```

**GCP**
```bash
# Login to GCP
gcloud auth login

# Set project
gcloud config set project PROJECT_ID

# Or use service account
export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account-key.json"
```

## 🚀 Initial Setup

### 1. Clone Repository

```bash
git clone <repository-url>
cd multi-cloud-gpu-terraform
```

### 2. Initialize Terraform

```bash
# Initialize providers and modules
terraform init

# Validate configuration
terraform validate
```

### 3. Configure Remote State (Recommended)

See [State Management](#state-management) section for detailed instructions.

## ⚙️ Environment Configuration

### Environment-Specific Variable Files

The project includes three environment configurations:

- `terraform.tfvars.dev` - Development environment
- `terraform.tfvars.staging` - Staging environment
- `terraform.tfvars.prod` - Production environment

### Using Environment Files

```bash
# Development
terraform plan -var-file="terraform.tfvars.dev"

# Staging
terraform plan -var-file="terraform.tfvars.staging"

# Production
terraform plan -var-file="terraform.tfvars.prod"
```

### Custom Configuration

Create your own `terraform.tfvars` file:

```hcl
cloud_provider = "aws"
region         = "us-east-1"
environment    = "production"
vm_name        = "gpu-prod"

tags = {
  Environment = "production"
  Project     = "digital-public-goods"
  Owner       = "devops-team"
}
```

## 🏗️ Provisioning Resources

### Step 1: Review Plan

Always preview changes before applying:

```bash
# Development environment
terraform plan -var-file="terraform.tfvars.dev" -out=dev.tfplan

# Production environment
terraform plan -var-file="terraform.tfvars.prod" -out=prod.tfplan
```

**What to Look For:**
- ✅ Number of resources to create/modify/destroy
- ✅ Resource names and tags
- ✅ Security group rules
- ✅ Estimated costs
- ✅ No unexpected changes

### Step 2: Apply Configuration

```bash
# Apply the plan
terraform apply "dev.tfplan"

# Or apply directly (with confirmation)
terraform apply -var-file="terraform.tfvars.dev"

# Auto-approve (use with caution)
terraform apply -var-file="terraform.tfvars.dev" -auto-approve
```

### Step 3: Verify Deployment

```bash
# View outputs
terraform output

# List all resources
terraform state list

# Inspect specific resource
terraform state show <resource_type.resource_name>
```

### Example: Provision AWS Development Environment

```bash
# 1. Plan
terraform plan -var-file="terraform.tfvars.dev" -out=dev.tfplan

# Output shows:
# Plan: 12 to add, 0 to change, 0 to destroy

# 2. Review plan details
terraform show dev.tfplan

# 3. Apply
terraform apply dev.tfplan

# 4. Get outputs
terraform output instance_public_ip
terraform output load_balancer_dns
```

## 🔄 Managing Infrastructure

### Viewing State

```bash
# List all resources
terraform state list

# Show resource details
terraform state show aws_instance.gpu_instance

# Show current outputs
terraform output
terraform output -json
```

### Updating Resources

```bash
# 1. Modify configuration or variables
vim terraform.tfvars.dev

# 2. Preview changes
terraform plan -var-file="terraform.tfvars.dev"

# 3. Apply changes
terraform apply -var-file="terraform.tfvars.dev"
```

### Targeted Updates

Update specific resources:

```bash
# Target specific resource
terraform apply -target=aws_instance.gpu_instance

# Target module
terraform apply -target=module.aws
```

### Refreshing State

```bash
# Refresh state from actual infrastructure
terraform refresh -var-file="terraform.tfvars.dev"
```

### Resource Tainting

Force resource recreation:

```bash
# Taint resource (mark for replacement)
terraform taint aws_instance.gpu_instance

# Untaint resource
terraform untaint aws_instance.gpu_instance

# Apply to recreate tainted resources
terraform apply -var-file="terraform.tfvars.dev"
```

### Importing Existing Resources

```bash
# Import existing AWS instance
terraform import aws_instance.gpu_instance i-1234567890abcdef0

# Import existing Azure VM
terraform import azurerm_linux_virtual_machine.gpu_vm /subscriptions/SUB_ID/resourceGroups/RG/providers/Microsoft.Compute/virtualMachines/VM_NAME
```

## 🗑️ Destroying Resources

### Preview Destruction

```bash
# See what will be destroyed
terraform plan -destroy -var-file="terraform.tfvars.dev"
```

### Destroy All Resources

```bash
# Interactive confirmation
terraform destroy -var-file="terraform.tfvars.dev"

# Auto-approve (use with caution)
terraform destroy -var-file="terraform.tfvars.dev" -auto-approve
```

### Targeted Destruction

```bash
# Destroy specific resource
terraform destroy -target=aws_instance.gpu_instance -var-file="terraform.tfvars.dev"

# Destroy module
terraform destroy -target=module.aws -var-file="terraform.tfvars.dev"
```

### Protection Against Accidental Destruction

Add lifecycle protection to critical resources:

```hcl
resource "aws_instance" "gpu_instance" {
  # ... other configuration ...
  
  lifecycle {
    prevent_destroy = true
  }
}
```

To destroy protected resources:

```bash
# 1. Remove lifecycle protection from code
# 2. Apply configuration
terraform apply

# 3. Destroy resources
terraform destroy
```

## 💾 State Management

### Local State (Development Only)

Default configuration uses local state:

```bash
# State file location
ls terraform.tfstate

# Backup file
ls terraform.tfstate.backup
```

### Remote State Setup

#### AWS S3 Backend

```bash
# 1. Create S3 bucket
aws s3 mb s3://terraform-state-dpg-prod --region us-east-1

# 2. Enable versioning
aws s3api put-bucket-versioning \
  --bucket terraform-state-dpg-prod \
  --versioning-configuration Status=Enabled

# 3. Enable encryption
aws s3api put-bucket-encryption \
  --bucket terraform-state-dpg-prod \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# 4. Create DynamoDB lock table
aws dynamodb create-table \
  --table-name terraform-state-lock-dpg \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# 5. Update backend.tf (uncomment AWS backend section)

# 6. Migrate state
terraform init -migrate-state
```

#### Azure Blob Storage Backend

```bash
# 1. Create resource group
az group create --name terraform-state-rg --location eastus

# 2. Create storage account
az storage account create \
  --resource-group terraform-state-rg \
  --name terraformstatevmdpg \
  --sku Standard_LRS \
  --encryption-services blob

# 3. Create container
az storage container create \
  --name tfstate \
  --account-name terraformstatevmdpg

# 4. Update backend.tf (uncomment Azure backend section)

# 5. Migrate state
terraform init -migrate-state
```

#### GCP Cloud Storage Backend

```bash
# 1. Create bucket
gsutil mb -p PROJECT_ID -l US gs://terraform-state-dpg-prod

# 2. Enable versioning
gsutil versioning set on gs://terraform-state-dpg-prod

# 3. Update backend.tf (uncomment GCP backend section)

# 4. Migrate state
terraform init -migrate-state
```

### State Operations

```bash
# List resources
terraform state list

# Show resource
terraform state show aws_instance.gpu_instance

# Move resource
terraform state mv aws_instance.old aws_instance.new

# Remove resource from state
terraform state rm aws_instance.gpu_instance

# Pull remote state
terraform state pull > terraform.tfstate.backup

# Push local state to remote
terraform state push terraform.tfstate
```

### State Locking

State locking prevents concurrent modifications:

```bash
# Force unlock if stuck (use with caution)
terraform force-unlock LOCK_ID
```

## 🐛 Troubleshooting

### Common Issues

#### Issue: "Error: No valid credential sources found"

**Solution:**
```bash
# AWS
aws configure
# or
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."

# Azure
az login

# GCP
gcloud auth login
```

#### Issue: "Error: Backend initialization required"

**Solution:**
```bash
terraform init -reconfigure
```

#### Issue: "Error: State lock acquisition failed"

**Solution:**
```bash
# Wait for lock to release (someone else is running terraform)
# Or force unlock (if process was terminated)
terraform force-unlock LOCK_ID
```

#### Issue: "Error: Resource already exists"

**Solution:**
```bash
# Import existing resource
terraform import <resource_type>.<name> <resource_id>

# Or remove from state and let Terraform recreate
terraform state rm <resource_type>.<name>
```

### Debug Mode

Enable debug logging:

```bash
# Set log level
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Run terraform command
terraform apply

# Review logs
cat terraform.log
```

### Validation

```bash
# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Check for errors
terraform plan -detailed-exitcode
```

## 📊 Cost Management

### Estimate Costs

```bash
# Use terraform plan to see resource counts
terraform plan -var-file="terraform.tfvars.dev"

# Use cloud provider cost calculators
# AWS: https://calculator.aws/
# Azure: https://azure.microsoft.com/pricing/calculator/
# GCP: https://cloud.google.com/products/calculator
```

### Environment Cost Estimates

- **Development**: $200-400/month (1 instance, no HA)
- **Staging**: $800-1,200/month (2-4 instances, basic HA)
- **Production**: $2,500-4,000/month (3-10 instances, full HA)

### Cost Optimization

```bash
# Destroy dev environment after hours
terraform destroy -var-file="terraform.tfvars.dev" -auto-approve

# Use spot instances (AWS)
# Configure in modules/aws/compute.tf

# Scale down staging on weekends
# Configure auto-scaling schedules
```

## 🔐 Security Best Practices

1. **Never commit secrets**
   ```bash
   # Add to .gitignore
   echo "*.tfvars" >> .gitignore
   echo "*.tfstate" >> .gitignore
   echo "*.tfstate.*" >> .gitignore
   ```

2. **Use environment variables**
   ```bash
   export TF_VAR_git_username="username"
   export TF_VAR_git_password="token"
   ```

3. **Enable state encryption**
   - AWS: S3 bucket encryption
   - Azure: Storage account encryption
   - GCP: Customer-managed encryption keys

4. **Restrict access**
   - Use IAM roles/policies
   - Enable MFA
   - Audit logs

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [IAM_RBAC_GUIDE.md](./IAM_RBAC_GUIDE.md) - Permission setup guide
- [TERRAFORM_ARCHITECTURE.md](./TERRAFORM_ARCHITECTURE.md) - Architecture overview

---

**Last Updated**: January 2026  
**Maintained By**: DevOps Team
