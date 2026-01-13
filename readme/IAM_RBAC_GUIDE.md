# IAM and RBAC Permissions Guide

This document outlines the IAM (AWS), RBAC (Azure), and IAM (GCP) permissions required for Terraform to provision and manage infrastructure.

## 📋 Overview

Each cloud provider requires specific permissions for Terraform to:
- Create and manage compute resources
- Configure networking components
- Set up load balancers
- Manage security groups/firewall rules
- Access remote state storage
- Enable monitoring and logging

## 🔐 Principle of Least Privilege

All permission sets follow the principle of least privilege:
- ✅ Grant only necessary permissions
- ✅ Separate permissions by environment
- ✅ Use service accounts/roles for automation
- ✅ Enable MFA for human access
- ✅ Rotate credentials regularly

## ☁️ AWS IAM Configuration

### Required IAM Policies

#### 1. Compute Permissions (EC2)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeImages",
        "ec2:CreateTags",
        "ec2:DescribeTags",
        "ec2:ModifyInstanceAttribute",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:RebootInstances"
      ],
      "Resource": "*"
    }
  ]
}
```

#### 2. Networking Permissions (VPC)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:DescribeVpcs",
        "ec2:ModifyVpcAttribute",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:DescribeSubnets",
        "ec2:ModifySubnetAttribute",
        "ec2:CreateInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:DescribeInternetGateways",
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:DescribeRouteTables",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable"
      ],
      "Resource": "*"
    }
  ]
}
```

#### 3. Security Group Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress"
      ],
      "Resource": "*"
    }
  ]
}
```

#### 4. Load Balancer Permissions (ALB)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:ModifyListener"
      ],
      "Resource": "*"
    }
  ]
}
```

#### 5. State Management Permissions (S3 + DynamoDB)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning"
      ],
      "Resource": [
        "arn:aws:s3:::terraform-state-dpg-*",
        "arn:aws:s3:::terraform-state-dpg-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-lock-dpg"
    }
  ]
}
```

### IAM Role/User Setup

#### For CI/CD (Automated Deployment)
```bash
# Create IAM user for Terraform
aws iam create-user --user-name terraform-automation

# Attach policies
aws iam attach-user-policy \
  --user-name terraform-automation \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/TerraformComputePolicy

# Create access keys
aws iam create-access-key --user-name terraform-automation
```

#### For Development (Human Users)
```bash
# Create IAM role with MFA requirement
aws iam create-role \
  --role-name TerraformDeveloperRole \
  --assume-role-policy-document file://trust-policy.json

# trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT_ID:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    }
  ]
}
```

## 🔷 Azure RBAC Configuration

### Required RBAC Roles

#### 1. Custom Role for Terraform
```json
{
  "Name": "Terraform Infrastructure Manager",
  "Description": "Custom role for Terraform to manage compute infrastructure",
  "Actions": [
    "Microsoft.Compute/virtualMachines/*",
    "Microsoft.Compute/disks/*",
    "Microsoft.Network/virtualNetworks/*",
    "Microsoft.Network/networkInterfaces/*",
    "Microsoft.Network/publicIPAddresses/*",
    "Microsoft.Network/networkSecurityGroups/*",
    "Microsoft.Network/loadBalancers/*",
    "Microsoft.Resources/deployments/*",
    "Microsoft.Resources/subscriptions/resourceGroups/*",
    "Microsoft.Storage/storageAccounts/*"
  ],
  "NotActions": [],
  "AssignableScopes": [
    "/subscriptions/SUBSCRIPTION_ID"
  ]
}
```

#### 2. Built-in Roles (Alternative)
```bash
# Option 1: Contributor role (full access)
az role assignment create \
  --assignee SERVICE_PRINCIPAL_ID \
  --role "Contributor" \
  --scope "/subscriptions/SUBSCRIPTION_ID"

# Option 2: Specific roles (recommended)
az role assignment create \
  --assignee SERVICE_PRINCIPAL_ID \
  --role "Virtual Machine Contributor" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/RG_NAME"

az role assignment create \
  --assignee SERVICE_PRINCIPAL_ID \
  --role "Network Contributor" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/RG_NAME"
```

### Service Principal Setup

```bash
# Create service principal for Terraform
az ad sp create-for-rbac \
  --name "terraform-automation" \
  --role "Terraform Infrastructure Manager" \
  --scopes /subscriptions/SUBSCRIPTION_ID

# Output:
# {
#   "appId": "APP_ID",
#   "displayName": "terraform-automation",
#   "password": "PASSWORD",
#   "tenant": "TENANT_ID"
# }

# Set environment variables for Terraform
export ARM_CLIENT_ID="APP_ID"
export ARM_CLIENT_SECRET="PASSWORD"
export ARM_SUBSCRIPTION_ID="SUBSCRIPTION_ID"
export ARM_TENANT_ID="TENANT_ID"
```

### State Storage Permissions

```bash
# Grant permissions for state storage
az role assignment create \
  --assignee SERVICE_PRINCIPAL_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/terraform-state-rg/providers/Microsoft.Storage/storageAccounts/terraformstatevmdpg"
```

## 🌐 GCP IAM Configuration

### Required IAM Roles

#### 1. Predefined Roles
```bash
# Compute Admin (for instances and instance groups)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="roles/compute.admin"

# Network Admin (for VPC and firewall rules)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="roles/compute.networkAdmin"

# Load Balancer Admin
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="roles/compute.loadBalancerAdmin"

# Storage Admin (for state storage)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="roles/storage.admin"
```

#### 2. Custom Role for Terraform (Recommended)
```yaml
title: "Terraform Infrastructure Manager"
description: "Custom role for Terraform compute infrastructure"
stage: "GA"
includedPermissions:
  # Compute permissions
  - compute.instances.create
  - compute.instances.delete
  - compute.instances.get
  - compute.instances.list
  - compute.instances.start
  - compute.instances.stop
  - compute.instances.update
  - compute.instanceTemplates.create
  - compute.instanceTemplates.delete
  - compute.instanceTemplates.get
  - compute.instanceTemplates.list
  - compute.instanceGroups.create
  - compute.instanceGroups.delete
  - compute.instanceGroups.get
  - compute.instanceGroups.list
  - compute.instanceGroups.update
  
  # Network permissions
  - compute.networks.create
  - compute.networks.delete
  - compute.networks.get
  - compute.networks.list
  - compute.networks.update
  - compute.subnetworks.create
  - compute.subnetworks.delete
  - compute.subnetworks.get
  - compute.subnetworks.list
  - compute.subnetworks.update
  - compute.firewalls.create
  - compute.firewalls.delete
  - compute.firewalls.get
  - compute.firewalls.list
  - compute.firewalls.update
  
  # Load balancer permissions
  - compute.backendServices.create
  - compute.backendServices.delete
  - compute.backendServices.get
  - compute.backendServices.list
  - compute.backendServices.update
  - compute.healthChecks.create
  - compute.healthChecks.delete
  - compute.healthChecks.get
  - compute.healthChecks.list
  - compute.urlMaps.create
  - compute.urlMaps.delete
  - compute.urlMaps.get
  - compute.urlMaps.list
  - compute.targetHttpProxies.create
  - compute.targetHttpProxies.delete
  - compute.globalForwardingRules.create
  - compute.globalForwardingRules.delete
```

### Service Account Setup

```bash
# Create service account for Terraform
gcloud iam service-accounts create terraform-automation \
  --display-name="Terraform Automation" \
  --description="Service account for Terraform infrastructure automation"

# Assign custom role
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:terraform-automation@PROJECT_ID.iam.gserviceaccount.com" \
  --role="projects/PROJECT_ID/roles/TerraformInfrastructureManager"

# Create and download key
gcloud iam service-accounts keys create ~/terraform-key.json \
  --iam-account=terraform-automation@PROJECT_ID.iam.gserviceaccount.com

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-key.json
```

### State Storage Permissions

```bash
# Grant storage permissions for state bucket
gsutil iam ch \
  serviceAccount:terraform-automation@PROJECT_ID.iam.gserviceaccount.com:objectAdmin \
  gs://terraform-state-dpg-prod
```

## 🔒 Security Best Practices

### 1. Credential Management

**DO:**
- ✅ Use environment variables for credentials
- ✅ Store credentials in secret management systems (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager)
- ✅ Rotate credentials regularly (90 days)
- ✅ Use service accounts for automation
- ✅ Enable MFA for human access

**DON'T:**
- ❌ Hardcode credentials in Terraform files
- ❌ Commit credentials to Git
- ❌ Share credentials via email/chat
- ❌ Use root/admin accounts
- ❌ Grant excessive permissions

### 2. Environment Separation

```bash
# Separate service accounts per environment
aws iam create-user --user-name terraform-dev
aws iam create-user --user-name terraform-staging
aws iam create-user --user-name terraform-prod

# Use different policies per environment
aws iam attach-user-policy \
  --user-name terraform-dev \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/TerraformDevPolicy

aws iam attach-user-policy \
  --user-name terraform-prod \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/TerraformProdPolicy
```

### 3. Audit and Monitoring

**AWS CloudTrail**
```bash
# Enable CloudTrail for all Terraform actions
aws cloudtrail create-trail \
  --name terraform-audit-trail \
  --s3-bucket-name terraform-audit-logs
```

**Azure Activity Log**
```bash
# Create diagnostic setting for audit logs
az monitor diagnostic-settings create \
  --name terraform-audit \
  --resource /subscriptions/SUBSCRIPTION_ID \
  --logs '[{"category": "Administrative", "enabled": true}]'
```

**GCP Cloud Audit Logs**
```bash
# Enable audit logs for Terraform service account
gcloud logging sinks create terraform-audit \
  bigquery.googleapis.com/projects/PROJECT_ID/datasets/terraform_audit \
  --log-filter='protoPayload.authenticationInfo.principalEmail="terraform-automation@PROJECT_ID.iam.gserviceaccount.com"'
```

## 📊 Permission Verification

### AWS
```bash
# Verify IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT_ID:user/terraform-automation \
  --action-names ec2:RunInstances ec2:CreateVpc \
  --resource-arns "*"
```

### Azure
```bash
# List assigned roles
az role assignment list \
  --assignee SERVICE_PRINCIPAL_ID \
  --output table
```

### GCP
```bash
# Test IAM permissions
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:terraform-automation@PROJECT_ID.iam.gserviceaccount.com"
```

## 🔄 Permission Updates

When adding new resources or capabilities, update IAM/RBAC permissions:

```bash
# AWS - Update policy
aws iam put-user-policy \
  --user-name terraform-automation \
  --policy-name TerraformComputePolicy \
  --policy-document file://updated-policy.json

# Azure - Update role assignment
az role assignment create \
  --assignee SERVICE_PRINCIPAL_ID \
  --role "New Role Name" \
  --scope /subscriptions/SUBSCRIPTION_ID

# GCP - Update service account permissions
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="roles/new.role"
```

## 📚 Additional Resources

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Azure RBAC Documentation](https://docs.microsoft.com/en-us/azure/role-based-access-control/)
- [GCP IAM Overview](https://cloud.google.com/iam/docs/overview)
- [Terraform AWS Provider Authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication)
- [Terraform Azure Provider Authentication](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
- [Terraform GCP Provider Authentication](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started#adding-credentials)

---

**Last Updated**: January 2026  
**Maintained By**: DevOps Team  
**Review Schedule**: Quarterly
