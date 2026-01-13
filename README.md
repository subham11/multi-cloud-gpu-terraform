# 🚀 Multi-Cloud GPU Infrastructure with Terraform

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-GPU_Instances-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![Azure](https://img.shields.io/badge/Azure-GPU_VMs-0078D4?logo=microsoft-azure)](https://azure.microsoft.com/)
[![GCP](https://img.shields.io/badge/GCP-GPU_Compute-4285F4?logo=google-cloud)](https://cloud.google.com/)

A production-ready, modular Terraform infrastructure for deploying GPU-accelerated workloads across AWS, Azure, and GCP with **single-click deployment**, automated NVIDIA driver installation, load balancing, and CI/CD pipelines.

## 📋 Table of Contents

- [Features](#-features)
- [Repository Structure](#-repository-structure)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Configuration](#-configuration)
- [Deployment](#-deployment)
- [Testing](#-testing)
- [Advanced Usage](#-advanced-usage)
- [Troubleshooting](#-troubleshooting)
- [Documentation](#-documentation)

## ✨ Features

### 🎯 Single-Click Deployment
- **Fully automated** infrastructure provisioning
- **Zero manual configuration** required
- Deploy to AWS, Azure, or GCP with one command

### 🏗️ Production-Ready Infrastructure
- **GPU instances**: AWS g5.4xlarge, Azure Standard_NV36ads_A10_v5, GCP with L4 GPU
- **Load balancers**: AWS ALB, Azure LB, GCP Global HTTPS LB with health checks
- **Auto-scaling**: Instance groups with health monitoring
- **Networking**: VPC, subnets, security groups, firewall rules

### 🔧 Automated Setup
- **NVIDIA drivers**: Automatic GPU driver installation (v550)
- **CUDA toolkit**: CUDA 12.4 pre-configured
- **Application deployment**: OAN UI Service + Agri Help backend
- **CI/CD pipeline**: Jenkins auto-configured with pipelines
- **Web server**: Nginx reverse proxy with SSL support

### 🧩 Modular Architecture
- **4 reusable modules**: common, aws, azure, gcp
- **6 script components**: nvidia-setup, git-helpers, app-deployment, nginx-config, jenkins-setup, deployment-report
- **35 organized files**: Average 55 lines per file for maintainability

### 🛡️ Security Best Practices
- Security groups with least privilege
- Encrypted credentials handling
- HTTPS support with SSL certificates
- Private subnets for compute resources

## 📁 Repository Structure

```
multi-cloud-gpu-terraform/
│
├── README.md                    # This file - main documentation
├── main.tf                      # Main orchestration (58 lines)
├── variables.tf                 # Input variable definitions
├── outputs.tf                   # Output definitions
├── providers.tf                 # Cloud provider configurations
├── terraform.tfvars.example     # Example configuration file
├── deploy.sh                    # Single-click deployment script
├── Makefile                     # Convenience commands
│
├── modules/                     # Terraform modules
│   ├── common/                  # Shared cloud-init scripts
│   │   ├── main.tf             # Cloud-init generation with Git credentials
│   │   ├── variables.tf        # Module inputs (git_username, git_password)
│   │   └── outputs.tf          # Cloud-init script output
│   │
│   ├── aws/                     # AWS infrastructure module (7 files, 333 lines)
│   │   ├── locals.tf           # Region & AMI selection logic
│   │   ├── networking.tf       # VPC, subnets, IGW, route tables
│   │   ├── security.tf         # Security groups (ALB, instance)
│   │   ├── compute.tf          # EC2 GPU instance (g5.4xlarge)
│   │   ├── load_balancer.tf    # ALB with target groups & health checks
│   │   ├── variables.tf        # Module input variables
│   │   └── outputs.tf          # Module outputs (IPs, DNS, URLs)
│   │
│   ├── azure/                   # Azure infrastructure module (6 files, 270 lines)
│   │   ├── networking.tf       # VNet, subnet, public IP
│   │   ├── security.tf         # Network security groups with rules
│   │   ├── compute.tf          # GPU VM (Standard_NV36ads_A10_v5)
│   │   ├── load_balancer.tf    # Azure load balancer with probes
│   │   ├── variables.tf        # Module input variables
│   │   └── outputs.tf          # Module outputs (IPs, URLs)
│   │
│   └── gcp/                     # GCP infrastructure module (5 files, 232 lines)
│       ├── compute.tf           # Instance template with L4 GPU + MIG
│       ├── firewall.tf          # Firewall rules for HTTP/HTTPS
│       ├── load_balancer.tf     # Global HTTPS load balancer
│       ├── variables.tf         # Module input variables
│       └── outputs.tf           # Module outputs (IPs, URLs)
│
├── scripts/                     # Setup and deployment scripts
│   ├── full-setup.sh            # Main orchestrator (180 lines)
│   └── components/              # Modular script components
│       ├── nvidia-setup.sh      # GPU driver installation (30 lines)
│       ├── git-helpers.sh       # Git authentication helpers (55 lines)
│       ├── app-deployment.sh    # Application deployment (60 lines)
│       ├── nginx-config.sh      # Web server configuration (120 lines)
│       ├── jenkins-setup.sh     # CI/CD setup (80 lines)
│       └── deployment-report.sh # Status reporting (90 lines)
│
├── ci-cd/                       # Jenkins pipeline configurations
│   ├── oan-ui-jenkinsfile       # OAN UI Service pipeline
│   ├── agri-help-jenkinsfile-template  # Agri Help backend pipeline
│   └── README.md                # CI/CD documentation
│
├── tests/                       # Testing tools and scripts
│   ├── README.md                # Testing documentation
│   ├── terraform_validation.sh  # Syntax and config validation
│   ├── terraform_plan_test.sh   # Generate deployment plans
│   ├── docker-compose.yml       # Local cloud emulators
│   └── local_test_variables.tf  # Test variable definitions
│
├── readme/                      # Detailed documentation (15 files)
│   ├── README.md                # Module structure overview
│   ├── ARCHITECTURE.md          # Architecture comparison
│   ├── QUICK_START.md           # Single-click deployment guide
│   ├── APP_DEPLOYMENT_GUIDE.md  # Application deployment
│   ├── JENKINS_SETUP_GUIDE.md   # CI/CD configuration
│   ├── LOAD_BALANCER_IMPLEMENTATION.md  # LB details
│   └── [9 more documentation files]
│
└── backup/                      # Original monolithic files
    ├── main.tf.backup           # Original 665-line main.tf
    ├── full-setup.sh.backup     # Original 583-line script
    └── outputs.tf.backup        # Original outputs file
```

## 🏗️ Architecture

### High-Level Design

```
┌─────────────────────────────────────────────────────────────────┐
│                     Terraform Orchestration                      │
│                          (main.tf)                               │
└────────────┬────────────────────────────────────────────────────┘
             │
             ├─────► Common Module (Cloud-init generation)
             │         └─► Embeds full-setup.sh with Git credentials
             │
             ├─────► AWS Module
             │         ├─► VPC + Subnets + IGW
             │         ├─► Security Groups (ALB, Instance)
             │         ├─► EC2 g5.4xlarge (NVIDIA A10G GPU)
             │         └─► Application Load Balancer
             │
             ├─────► Azure Module
             │         ├─► VNet + Subnet + Public IP
             │         ├─► Network Security Group
             │         ├─► Standard_NV36ads_A10_v5 (NVIDIA A10)
             │         └─► Azure Load Balancer
             │
             └─────► GCP Module
                       ├─► Instance Template with L4 GPU
                       ├─► Managed Instance Group (MIG)
                       ├─► Firewall Rules
                       └─► Global HTTPS Load Balancer
```

### Deployment Flow

```
1. User runs: ./deploy.sh
   │
   ├─► Prompts for: cloud_provider, region, vm_name
   │
2. Terraform creates infrastructure
   │
   ├─► Provisions: VPC, subnets, security groups
   ├─► Creates: GPU instance with cloud-init
   ├─► Configures: Load balancer + health checks
   │
3. Cloud-init executes full-setup.sh on instance
   │
   ├─► Phase 1: NVIDIA Driver + CUDA (10-15 min)
   ├─► Phase 2: Node.js v18 installation
   ├─► Phase 3: Git clone applications
   ├─► Phase 4: Application deployment (OAN UI + Agri Help)
   ├─► Phase 5: Nginx configuration (ports 5000, 3000)
   ├─► Phase 6: Jenkins installation + auto-configuration
   ├─► Phase 7: Deployment report generation
   │
4. Services become available
   │
   ├─► Application: http://<LB_DNS>/ (port 80/443)
   ├─► OAN UI: http://<INSTANCE_IP>:5000
   ├─► Agri Help: http://<INSTANCE_IP>:3000
   └─► Jenkins: http://<INSTANCE_IP>:8080
```

### Module Dependencies

```
main.tf
  │
  ├── module "common"
  │     └── Generates cloud-init script with Git credentials
  │
  ├── module "aws" (conditionally created if cloud_provider == "aws")
  │     ├── Depends on: module.common.cloud_init_script
  │     ├── Creates: VPC, EC2, ALB
  │     └── Uses: user_data_script from common module
  │
  ├── module "azure" (conditionally created if cloud_provider == "azure")
  │     ├── Depends on: module.common.cloud_init_script
  │     ├── Creates: VNet, VM, LB
  │     └── Uses: custom_data from common module
  │
  └── module "gcp" (conditionally created if cloud_provider == "gcp")
        ├── Depends on: module.common.cloud_init_script
        ├── Creates: Instance Template, MIG, Global LB
        └── Uses: startup-script metadata from common module
```

### Component Architecture

**Terraform Layer** (Infrastructure as Code)
- Modular design with 4 independent modules
- Single responsibility: each file handles one concern
- Reusable across environments (dev, staging, prod)

**Script Layer** (Application Deployment)
- 6 independent components sourced by orchestrator
- Fallback mechanisms for public/private repos
- Idempotent operations for safe re-runs

**Application Layer** (Services)
- **Backend**: FastAPI RAG service (port 8000) with AWS Bedrock/OpenRouter, Qdrant vector DB, Redis
- **Frontend**: Next.js 16 app (port 3000) with ChatGPT-style UI
- **OAN UI**: React/Vite service (port 5000) with multi-tenant support
- **Transcribe**: Audio transcription service with omnilingual ASR

## 🔧 Prerequisites

### Required Tools

1. **Terraform** (v1.0+)
   ```bash
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **Cloud CLI Tools** (for the provider you're using)
   
   **AWS CLI:**
   ```bash
   brew install awscli  # macOS
   # or
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```
   
   **Azure CLI:**
   ```bash
   brew install azure-cli  # macOS
   # or
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```
   
   **Google Cloud SDK:**
   ```bash
   brew install google-cloud-sdk  # macOS
   # or
   curl https://sdk.cloud.google.com | bash
   ```

### Cloud Provider Setup

#### AWS Setup
```bash
# Configure credentials
aws configure
# Enter: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, region

# Verify authentication
aws sts get-caller-identity
```

**Required IAM Permissions:**
- EC2: Full access (create instances, security groups, VPCs)
- ELB: Full access (create load balancers)
- IAM: PassRole (for instance profiles)

#### Azure Setup
```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "Your-Subscription-Name"

# Verify authentication
az account show
```

**Required Permissions:**
- Contributor role on subscription or resource group

#### GCP Setup
```bash
# Authenticate
gcloud auth application-default login

# Set project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

**Required APIs:**
- Compute Engine API
- Cloud Resource Manager API

### Optional: Git Credentials

If deploying private repositories:
```bash
# Set credentials as environment variables
export TF_VAR_git_username="your-email@example.com"
export TF_VAR_git_password="your-personal-access-token"
```

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/subham11/multi-cloud-gpu-terraform.git
cd multi-cloud-gpu-terraform
```

### 2. Configure Variables
```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit configuration
nano terraform.tfvars
```

**Minimal Configuration:**
```hcl
cloud_provider = "aws"           # Choose: aws, azure, gcp
region         = "ap-south-1"    # Mumbai region for AWS
vm_name        = "my-gpu-instance"
```

**With GCP:**
```hcl
cloud_provider = "gcp"
region         = "asia-south1"
vm_name        = "my-gpu-instance"
gcp_project_id = "your-gcp-project-id"  # Required for GCP
```

### 3. Deploy Infrastructure
```bash
# Single-click deployment
./deploy.sh

# Or manually
terraform init
terraform plan
terraform apply
```

### 4. Access Your Services

After 35-50 minutes (includes NVIDIA driver installation), access:

- **Load Balancer**: Outputs show `lb_url`
- **OAN UI Service**: `http://<INSTANCE_IP>:5000`
- **Agri Help Backend**: `http://<INSTANCE_IP>:3000`
- **Jenkins CI/CD**: `http://<INSTANCE_IP>:8080` (admin/admin123)

### 5. Clean Up
```bash
terraform destroy
```

## ⚙️ Configuration

### Required Variables

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `cloud_provider` | Target cloud (aws, azure, gcp) | `"aws"` | ✅ Yes |
| `region` | Cloud region | `"ap-south-1"` | ✅ Yes |
| `vm_name` | Instance name | `"gpu-instance"` | ✅ Yes |
| `gcp_project_id` | GCP project ID | `"my-project"` | Only for GCP |

### Optional Variables

| Variable | Description | Default | Sensitive |
|----------|-------------|---------|-----------|
| `aws_certificate_arn` | ACM certificate for HTTPS | `null` | No |
| `azure_ssh_public_key` | SSH public key for Azure | Generated | Yes |
| `gcp_ssl_certificate_id` | GCP SSL certificate | `null` | No |
| `git_username` | Git username/email | `""` | Yes |
| `git_password` | Git password/token | `""` | Yes |

### Region Selection

**AWS Regions** (GPU instance support):
- `ap-south-1` - Mumbai, India
- `ap-south-2` - Hyderabad, India
- `us-east-1` - N. Virginia, USA
- `us-west-2` - Oregon, USA
- `eu-west-1` - Ireland

**Azure Regions**:
- `southeastasia` - Singapore
- `eastasia` - Hong Kong
- `centralindia` - Pune, India
- `westus` - California, USA

**GCP Regions** (L4 GPU availability):
- `asia-south1` - Mumbai, India
- `asia-southeast1` - Singapore
- `us-central1` - Iowa, USA
- `us-west1` - Oregon, USA

### Environment Variables

Set sensitive values via environment variables (recommended for CI/CD):

```bash
export TF_VAR_cloud_provider="aws"
export TF_VAR_region="ap-south-1"
export TF_VAR_vm_name="gpu-instance"
export TF_VAR_git_username="user@example.com"
export TF_VAR_git_password="ghp_xxxxxxxxxxxxx"
```

## 🎯 Deployment

### Using Deploy Script (Recommended)

The `deploy.sh` script provides an interactive deployment experience:

```bash
./deploy.sh
```

**What it does:**
1. ✅ Validates Terraform installation
2. ✅ Validates cloud provider credentials
3. ✅ Prompts for configuration (provider, region, vm_name)
4. ✅ Creates `terraform.tfvars` automatically
5. ✅ Runs `terraform init` and `terraform plan`
6. ✅ Shows estimated deployment time
7. ✅ Executes `terraform apply` with confirmation
8. ✅ Displays all service URLs and credentials
9. ✅ Saves deployment info to `deployment-info.txt`

### Manual Deployment

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# View outputs
terraform output
```

### Deployment Targets by Cloud

**Deploy to AWS only:**
```bash
terraform apply -target=module.aws
```

**Deploy to Azure only:**
```bash
terraform apply -target=module.azure
```

**Deploy to GCP only:**
```bash
terraform apply -target=module.gcp
```

### Deployment Timeline

| Phase | Duration | Description |
|-------|----------|-------------|
| Terraform Provision | 5-8 min | Create VPC, instances, load balancers |
| Instance Boot | 2-3 min | Instance initialization |
| NVIDIA Drivers | 10-15 min | GPU driver installation + CUDA |
| Node.js Setup | 2-3 min | Node.js v18 installation |
| Application Deploy | 5-10 min | Clone repos, npm install, build |
| Jenkins Setup | 5-10 min | Install + auto-configure Jenkins |
| **Total** | **35-50 min** | Complete deployment |

### What Gets Deployed

**Infrastructure:**
- ✅ GPU-accelerated compute instance
- ✅ Load balancer with health checks
- ✅ VPC/VNet with public subnets
- ✅ Security groups/NSGs with firewall rules
- ✅ Public IP addresses

**Software Stack:**
- ✅ NVIDIA Driver 550 + CUDA 12.4
- ✅ Node.js v18 + npm
- ✅ Docker + Docker Compose
- ✅ Nginx reverse proxy
- ✅ Jenkins CI/CD server
- ✅ Git with credential helpers

**Applications:**
- ✅ OAN UI Service (React + Vite, port 5000)
- ✅ Agri Help Backend (FastAPI RAG, port 8000)
- ✅ Agri Help Frontend (Next.js 16, port 3000)
- ✅ Transcribe Service (Audio transcription)
- ✅ Supporting services: PostgreSQL, Redis, Qdrant

**CI/CD:**
- ✅ Jenkins with pre-installed plugins
- ✅ Pre-configured pipelines
- ✅ Admin user (admin/admin123)
- ✅ GitHub webhook integration ready

## 🧪 Testing

### Local Validation (No Cloud Access Required)

```bash
# Validate Terraform syntax and configuration
make validate

# Or manually
bash tests/terraform_validation.sh
```

**What it checks:**
- ✅ Terraform syntax (formatting)
- ✅ Variable definitions
- ✅ Resource configurations
- ✅ Module dependencies

### Generate Deployment Plans

Preview what will be created without actually deploying:

```bash
# AWS deployment plan
make plan-aws

# Azure deployment plan
make plan-azure

# GCP deployment plan
make plan-gcp

# Custom plan
bash tests/terraform_plan_test.sh aws us-east-1 test-instance
```

**Note:** Authentication errors for unused providers are expected and can be ignored.

### Local Cloud Emulation (Optional)

Test with local cloud emulators:

```bash
# Start LocalStack (AWS) + Azurite (Azure)
make sandbox-up

# Configure AWS CLI for LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_ENDPOINT_URL=http://localhost:4566

# Test Terraform with emulator
terraform init
terraform plan

# Stop emulators
make sandbox-down
```

### Module Testing

Test individual modules:

```bash
# Test AWS module
cd modules/aws
terraform init
terraform plan \
  -var="vm_name=test" \
  -var="region=us-east-1" \
  -var="user_data_script=echo test"

# Test Azure module
cd modules/azure
terraform init
terraform plan \
  -var="vm_name=test" \
  -var="region=eastus" \
  -var="custom_data=echo test"
```

### Testing Documentation

See [tests/README.md](tests/README.md) for comprehensive testing guide.

## 🔨 Advanced Usage

### Multi-Environment Deployment

**Development Environment:**
```bash
terraform workspace new dev
terraform workspace select dev
terraform apply -var-file=environments/dev.tfvars
```

**Production Environment:**
```bash
terraform workspace new prod
terraform workspace select prod
terraform apply -var-file=environments/prod.tfvars
```

### Custom Module Configuration

Use modules in your own Terraform configurations:

```hcl
module "gpu_aws_dev" {
  source = "github.com/subham11/multi-cloud-gpu-terraform//modules/aws"
  
  vm_name          = "dev-gpu-instance"
  region           = "us-east-1"
  user_data_script = file("${path.module}/custom-init.sh")
}

module "gpu_aws_prod" {
  source = "github.com/subham11/multi-cloud-gpu-terraform//modules/aws"
  
  vm_name          = "prod-gpu-instance"
  region           = "ap-south-1"
  user_data_script = file("${path.module}/custom-init.sh")
}
```

### HTTPS/SSL Configuration

**AWS with ACM Certificate:**
```hcl
# terraform.tfvars
cloud_provider      = "aws"
region              = "us-east-1"
vm_name             = "gpu-instance"
aws_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxx"
```

**GCP with SSL Certificate:**
```hcl
# terraform.tfvars
cloud_provider         = "gcp"
region                 = "us-central1"
vm_name                = "gpu-instance"
gcp_project_id         = "my-project"
gcp_ssl_certificate_id = "projects/my-project/global/sslCertificates/my-cert"
```

### Custom Application Deployment

Modify `scripts/components/app-deployment.sh` to deploy your own applications:

```bash
# Add your application to app-deployment.sh
deploy_custom_app() {
    echo "[INFO] Deploying Custom Application..."
    
    cd /opt
    git clone https://github.com/yourorg/your-app.git
    cd your-app
    
    npm install
    npm run build
    
    # Start as systemd service
    sudo systemctl enable your-app
    sudo systemctl start your-app
}
```

### Makefile Commands

```bash
# Validation
make validate          # Validate Terraform configuration
make fmt               # Format Terraform files

# Planning
make plan-aws          # Generate AWS deployment plan
make plan-azure        # Generate Azure deployment plan
make plan-gcp          # Generate GCP deployment plan

# Deployment
make deploy            # Interactive deployment
make deploy-aws        # Deploy to AWS directly
make deploy-azure      # Deploy to Azure directly
make deploy-gcp        # Deploy to GCP directly

# Testing
make sandbox-up        # Start local cloud emulators
make sandbox-down      # Stop local cloud emulators
make test              # Run all tests

# Cleanup
make destroy           # Destroy infrastructure
make clean             # Clean Terraform cache
```

## 🐛 Troubleshooting

### Common Issues

**Issue 1: Authentication Failed**
```bash
# AWS
Error: Error retrieving credentials from AWS: NoCredentialProviders

Solution:
aws configure
# Or set credentials
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
```

**Issue 2: GPU Instance Unavailable**
```bash
Error: Instance type g5.4xlarge is not supported in region eu-north-1

Solution:
# Use a region with GPU support
region = "us-east-1"  # or ap-south-1, us-west-2
```

**Issue 3: NVIDIA Driver Installation Failed**
```bash
# SSH into instance
ssh -i key.pem ubuntu@<INSTANCE_IP>

# Check cloud-init logs
sudo tail -f /var/log/cloud-init-output.log

# Manually install drivers
sudo /opt/scripts/nvidia-setup.sh
```

**Issue 4: Services Not Starting**
```bash
# Check deployment report
cat /opt/deployment_report.txt

# Check service status
sudo systemctl status oan-ui-service
sudo systemctl status agri-help-backend
sudo systemctl status jenkins

# Check Nginx configuration
sudo nginx -t
sudo systemctl restart nginx
```

**Issue 5: Terraform State Locked**
```bash
Error: Error locking state: Error acquiring the state lock

Solution:
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Getting Help

1. Check [readme/](readme/) directory for detailed documentation
2. Review [tests/README.md](tests/README.md) for testing issues
3. Check cloud-init logs: `/var/log/cloud-init-output.log`
4. Check deployment report: `/opt/deployment_report.txt`
5. Open an issue on GitHub

### Logs and Debugging

**SSH Access:**
```bash
# Get instance IP from Terraform output
terraform output instance_public_ip

# SSH into instance
ssh -i ~/.ssh/id_rsa ubuntu@<INSTANCE_IP>
```

**Key Log Files:**
```bash
# Cloud-init execution
/var/log/cloud-init-output.log

# Deployment report
/opt/deployment_report.txt

# NVIDIA driver installation
/var/log/nvidia-installer.log

# Application logs
/opt/oan-ui-service/logs/
/opt/agri_help/backend/logs/

# Jenkins logs
/var/log/jenkins/jenkins.log

# Nginx logs
/var/log/nginx/access.log
/var/log/nginx/error.log
```

## 📚 Documentation

### Quick Links

- [**QUICK_START.md**](readme/QUICK_START.md) - Single-click deployment guide
- [**ARCHITECTURE.md**](readme/ARCHITECTURE.md) - Detailed architecture comparison
- [**APP_DEPLOYMENT_GUIDE.md**](readme/APP_DEPLOYMENT_GUIDE.md) - Application deployment details
- [**JENKINS_SETUP_GUIDE.md**](readme/JENKINS_SETUP_GUIDE.md) - CI/CD configuration
- [**LOAD_BALANCER_IMPLEMENTATION.md**](readme/LOAD_BALANCER_IMPLEMENTATION.md) - Load balancer details
- [**tests/README.md**](tests/README.md) - Testing guide

### All Documentation Files

```
readme/
├── README.md                        # Module structure overview
├── ARCHITECTURE.md                  # Architecture comparison
├── ARCHITECTURE_VALIDATION.md       # Validation results
├── QUICK_START.md                   # Single-click deployment
├── APP_DEPLOYMENT_GUIDE.md          # Application deployment
├── JENKINS_SETUP_GUIDE.md           # CI/CD setup
├── JENKINS_QUICK_START.md           # Jenkins quick start
├── CI-CD_PIPELINE_WORKFLOW.md       # Pipeline workflows
├── GITHUB_WEBHOOK_SETUP.md          # Webhook configuration
├── LOAD_BALANCER_IMPLEMENTATION.md  # Load balancer guide
├── NVIDIA_CUDA_DEPLOYMENT.md        # GPU setup details
├── MIGRATION_COMPLETE.md            # Migration summary
├── SINGLE_CLICK_IMPLEMENTATION.md   # Implementation details
├── FIX_MAIN_TF.md                   # Troubleshooting
└── [1 more file]
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

- AWS for EC2 GPU instances
- Azure for GPU virtual machines
- Google Cloud for GPU compute
- NVIDIA for GPU drivers and CUDA toolkit
- Terraform for infrastructure as code
- Community contributors

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/subham11/multi-cloud-gpu-terraform/issues)
- **Documentation**: [readme/](readme/)
- **Email**: Contact repository maintainer

---

**⭐ Star this repository if you find it helpful!**

Built with ❤️ for GPU-accelerated multi-cloud deployments
