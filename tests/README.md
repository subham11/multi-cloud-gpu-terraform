# Testing Guide for Multi-Cloud GPU Terraform

This directory contains scripts and tools for validating Terraform configurations without deploying to actual cloud infrastructure.

## Quick Start

### 1. Validate Configuration (No Cloud Access Required)
```bash
# Run all validation checks
make validate

# Or manually
bash tests/terraform_validation.sh
```

This checks:
- ✓ Terraform syntax and format
- ✓ Variable definitions
- ✓ Configuration validity for each cloud provider
- ✓ Resource definitions are correct

### 2. Generate Deployment Plans
```bash
# Preview AWS deployment (no resources created)
make plan-aws

# Preview Azure deployment
make plan-azure

# Preview GCP deployment
make plan-gcp

# Or manually:
bash tests/terraform_plan_test.sh aws ap-south-1 test-gpu-instance
```

**Note:** You may see authentication errors for unused providers (e.g., Azure/GCP errors when testing AWS). This is **expected behavior** and can be safely ignored. The important part is that your selected cloud provider's resources are shown in the plan.

Plans show exactly what will be created without actually creating anything.

### 3. Local Sandbox Testing (Optional)
Start local cloud emulators for deeper testing:

```bash
# Start LocalStack (AWS) + Azurite (Azure)
make sandbox-up

# Configure AWS CLI to use LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_ENDPOINT_URL=http://localhost:4566

# Test with LocalStack endpoint
aws ec2 describe-instances --endpoint-url=http://localhost:4566

# View logs
make sandbox-logs

# Stop when done
make sandbox-down
```

## Testing Tools

### Built-in Terraform Commands
- `terraform validate` - Check syntax and structure
- `terraform plan` - Preview changes without applying
- `terraform fmt` - Check/fix code formatting

### Static Analysis Tools (Optional)

**Install TFLint:**
```bash
# macOS
brew install tflint

# Or download from: https://github.com/terraform-linters/tflint
```

**Run linting:**
```bash
make lint
```

**Popular TFLint checks:**
- Resource naming conventions
- Unused variables
- Deprecated attributes
- Module best practices

### Local Cloud Emulation

**LocalStack** (AWS emulator)
- Port: 4566
- Emulates: EC2, IAM, S3, RDS, etc.
- Perfect for testing before deploying

**Azurite** (Azure Storage emulator)
- Ports: 10000-10002
- Emulates: Blob, Queue, Table storage
- Good for storage testing

## Test Scenarios

### Scenario 1: Validate All Configurations
```bash
make test
```
Runs: validate → format → plan-aws → plan-azure → plan-gcp

### Scenario 2: Test AWS Region Preference Logic
```bash
# Test Mumbai preference
bash tests/terraform_plan_test.sh aws ap-south-1

# Test fallback to us-east-1 (unsupported region)
bash tests/terraform_plan_test.sh aws eu-west-1
```

### Scenario 3: Test Variable Validation
```bash
# Invalid cloud provider (should fail)
terraform validate -var 'cloud_provider=invalid' -var 'region=us-east-1'

# Valid configuration (should pass)
terraform validate -var 'cloud_provider=aws' -var 'region=ap-south-1'
```

## Common Issues & Solutions

### Issue: "Provider not configured"
**Solution:** This is expected! Plans work without actual cloud credentials. Just validating the configuration.

### Issue: "Module not found"
**Solution:** Run `terraform init -backend=false` first

### Issue: TFLint not installed
**Solution:** 
```bash
# macOS
brew install tflint

# Linux
wget https://github.com/terraform-linters/tflint/releases/download/v0.50.0/tflint_linux_amd64.zip
unzip tflint_linux_amd64.zip && sudo mv tflint /usr/local/bin/
```

### Issue: Docker not running
**Solution:** Only needed for `make sandbox-up`. Skip if not testing with LocalStack.

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Terraform Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - run: make validate
      - run: make plan-aws
      - run: make plan-azure
      - run: make plan-gcp
```

### GitLab CI Example
```yaml
validate:
  image: hashicorp/terraform:latest
  script:
    - make validate
    - make plan-aws
    - make plan-azure
    - make plan-gcp
```

## What Gets Tested

| Test | Command | Requires Cloud Credentials |
|------|---------|---------------------------|
| Syntax validation | `terraform validate` | No |
| Code formatting | `terraform fmt` | No |
| Plan generation | `terraform plan` | No |
| Static analysis | `tflint` | No |
| LocalStack testing | `docker-compose up` | No |
| Actual deployment | `terraform apply` | **Yes** |

## Before Production Deployment

1. ✅ Run `make validate` - All checks must pass
2. ✅ Review plan output carefully: `make plan-aws` (or azure/gcp)
3. ✅ Verify region selection logic with your regions
4. ✅ Check AMI IDs for AWS (region-specific)
5. ✅ Set up proper state backend (S3, Terraform Cloud, etc.)
6. ✅ Configure IAM policies with least privilege
7. ✅ Run `terraform apply` with approval

## Additional Resources

- [Terraform Testing Best Practices](https://www.terraform.io/docs/language/tests/overview.html)
- [LocalStack Documentation](https://docs.localstack.cloud/)
- [Terraform Plan Documentation](https://www.terraform.io/docs/cli/commands/plan.html)
- [TFLint Rules](https://github.com/terraform-linters/tflint/tree/master/docs/rules)
