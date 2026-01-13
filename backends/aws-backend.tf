# Note: Do not keep multiple active backend blocks. Use this file as a template
# and configure via terraform init -backend-config=backends/aws-backend.hcl
# 4. Run: terraform init

# ============================================================================
# Terraform Backend - S3 + DynamoDB
# ============================================================================
/*
terraform {
  backend "s3" {
    # S3 bucket for storing Terraform state
    bucket         = "my-org-terraform-state"
    
    # Path to state file within bucket
    key            = "multi-cloud-gpu/terraform.tfstate"
    
    # AWS region where S3 bucket is located
    region         = "ap-south-1"
    
    # Enable state encryption at rest
    encrypt        = true
    
    # DynamoDB table for state locking (prevents concurrent modifications)
    dynamodb_table = "terraform-state-lock"
  }
}
*/

# ============================================================================
# Setup Instructions
# ============================================================================

/*
## Step 1: Create S3 Bucket

aws s3api create-bucket \
  --bucket my-org-terraform-state \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

## Step 2: Enable Versioning

aws s3api put-bucket-versioning \
  --bucket my-org-terraform-state \
  --versioning-configuration Status=Enabled

## Step 3: Enable Encryption

aws s3api put-bucket-encryption \
  --bucket my-org-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

## Step 4: Block Public Access

aws s3api put-public-access-block \
  --bucket my-org-terraform-state \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

## Step 5: Create DynamoDB Table for State Locking

aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1

## Step 6: Enable Point-in-Time Recovery (PITR)

aws dynamodb update-continuous-backups \
  --table-name terraform-state-lock \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true \
  --region ap-south-1

## Step 7: Uncomment the terraform block above and run

terraform init

# Terraform will detect the remote state and migrate local state automatically.

*/

# ============================================================================
# Terraform Backend - Local (Default)
# Used when remote backend is not configured
# ============================================================================

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
