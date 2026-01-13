# Multi-Cloud GPU Infrastructure - Modular Architecture

## 📁 Project Structure

```
multi-cloud-gpu-terraform/
├── main.tf                      # Main orchestration (calls modules)
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values
├── providers.tf                 # Cloud provider configurations
├── terraform.tfvars            # Variable values (gitignored)
├── deploy.sh                   # Deployment automation script
│
├── modules/                    # Terraform modules
│   ├── common/                 # Shared cloud-init scripts
│   │   ├── main.tf            # Cloud-init generation
│   │   ├── variables.tf       # Module inputs
│   │   └── outputs.tf         # Module outputs
│   │
│   ├── aws/                    # AWS infrastructure module
│   │   ├── locals.tf          # AMI selection, region logic
│   │   ├── networking.tf      # VPC, subnets, IGW, routes
│   │   ├── security.tf        # Security groups
│   │   ├── compute.tf         # EC2 GPU instance
│   │   ├── load_balancer.tf   # ALB, target groups, listeners
│   │   ├── variables.tf       # Module inputs
│   │   └── outputs.tf         # Module outputs
│   │
│   ├── azure/                  # Azure infrastructure module
│   │   ├── networking.tf      # VNet, subnet, public IP
│   │   ├── security.tf        # Network security groups
│   │   ├── compute.tf         # GPU virtual machine
│   │   ├── load_balancer.tf   # Azure load balancer
│   │   ├── variables.tf       # Module inputs
│   │   └── outputs.tf         # Module outputs
│   │
│   └── gcp/                    # GCP infrastructure module
│       ├── compute.tf          # Instance template, MIG
│       ├── firewall.tf         # Firewall rules
│       ├── load_balancer.tf    # Global load balancer
│       ├── variables.tf        # Module inputs
│       └── outputs.tf          # Module outputs
│
├── scripts/                    # Setup and deployment scripts
│   ├── full-setup.sh           # Main orchestrator script
│   └── components/             # Modular script components
│       ├── nvidia-setup.sh     # GPU driver installation
│       ├── git-helpers.sh      # Git authentication helpers
│       ├── app-deployment.sh   # Application deployment
│       ├── nginx-config.sh     # Web server configuration
│       ├── jenkins-setup.sh    # CI/CD installation
│       └── deployment-report.sh # Report generation
│
├── ci-cd/                      # Jenkins pipeline configurations
│   ├── oan-ui-jenkinsfile
│   ├── agri-help-jenkinsfile-template
│   └── README.md
│
└── readme/                     # Documentation
    ├── architecture.md
    ├── deployment-guide.md
    ├── testing-guide.md
    └── security-best-practices.md
```

## 🏗️ Architecture Overview

### Terraform Modules

The infrastructure is organized into reusable, cloud-specific modules:

#### **Common Module** (`modules/common/`)
- Generates cloud-init scripts for all providers
- Handles Git credentials securely
- Embeds full-setup.sh script

#### **AWS Module** (`modules/aws/`)
- **Networking**: VPC with dual-AZ subnets, Internet Gateway
- **Security**: ALB and instance security groups
- **Compute**: GPU instance (g5.4xlarge)
- **Load Balancer**: Application Load Balancer with health checks
- **Features**: Region preference (Mumbai > Chennai > US-East-1)

#### **Azure Module** (`modules/azure/`)
- **Networking**: VNet with subnet and public IP
- **Security**: Network security groups with inbound rules
- **Compute**: GPU VM (Standard_NV36ads_A10_v5)
- **Load Balancer**: Standard LB with health probes

#### **GCP Module** (`modules/gcp/`)
- **Compute**: Instance template with L4 GPU
- **Firewall**: HTTP/HTTPS and health check rules
- **Load Balancer**: Global HTTPS load balancer
- **Scaling**: Managed Instance Group (MIG)

### Script Components

Setup scripts are broken into logical, reusable components:

| Component | Purpose | Dependencies |
|-----------|---------|--------------|
| `nvidia-setup.sh` | GPU driver & CUDA installation | lspci, curl |
| `git-helpers.sh` | Clone with authentication fallback | git |
| `app-deployment.sh` | Deploy OAN UI & Agri Help | Node.js, git-helpers |
| `nginx-config.sh` | Configure reverse proxy | nginx |
| `jenkins-setup.sh` | Install & configure Jenkins | Java 17 |
| `deployment-report.sh` | Generate status report | - |

## 🚀 Quick Start

### 1. Deploy Infrastructure

```bash
./deploy.sh
```

Follow the prompts to:
- Select cloud provider (aws/azure/gcp)
- Choose region
- Enter VM name
- Provide Git credentials (if deploying private repos)

### 2. Verify Deployment

```bash
# Connect to instance
ssh -i your-key.pem ubuntu@INSTANCE_IP

# Check deployment report
cat /opt/deployment-info.txt

# View logs
tail -f /var/log/bootstrap.log
```

### 3. Access Applications

- **OAN UI Service**: http://LOAD_BALANCER_IP/
- **Agri Help**: http://INSTANCE_IP:3000
- **Jenkins**: http://INSTANCE_IP:8080 (admin/admin123)

## 🔧 Customization

### Add New Cloud Provider

1. Create new module: `modules/newcloud/`
2. Implement required files:
   - `variables.tf` - Module inputs
   - `compute.tf` - VM resources
   - `networking.tf` - Network resources
   - `outputs.tf` - Module outputs
3. Update `main.tf` to call new module
4. Add outputs to root `outputs.tf`

### Add New Application

1. Update `scripts/components/app-deployment.sh`:
   ```bash
   # Deploy New App
   NEW_APP_DEPLOYED=false
   if clone_repo "https://github.com/user/repo" "$NEW_APP_DIR" "New App"; then
     cd "$NEW_APP_DIR"
     npm install && npm run build
     NEW_APP_DEPLOYED=true
   fi
   ```

2. Update `scripts/components/nginx-config.sh` with new server block

3. Add security group rules in module security files

### Modify Script Behavior

Each component is independent - edit individual files in `scripts/components/`:

```bash
# Disable Jenkins installation
# Comment out in scripts/full-setup.sh:
# install_jenkins "$JENKINS_LOG"

# Change Node.js version
# Edit scripts/components/app-deployment.sh:
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
```

## 📝 Module Inputs

### Common Module
- `git_username` - Git username for private repos (sensitive)
- `git_password` - Git password/token (sensitive)
- `setup_script_path` - Path to full-setup.sh

### AWS Module
- `vm_name` - Resource name prefix
- `region` - AWS region
- `instance_type` - EC2 instance type (default: g5.4xlarge)
- `user_data_script` - Base64 encoded cloud-init script

### Azure Module
- `vm_name` - Resource name prefix
- `region` - Azure region
- `vm_size` - VM size (default: Standard_NV36ads_A10_v5)
- `ssh_public_key` - SSH public key for admin user

### GCP Module
- `vm_name` - Resource name prefix
- `region` - GCP region
- `project_id` - GCP project ID
- `machine_type` - Machine type (default: g2-standard-16)
- `gpu_type` - GPU accelerator (default: nvidia-l4)

## 📊 Module Outputs

Each module provides structured outputs for accessing resources:

```hcl
# AWS
output "aws_instance_public_ip"
output "aws_load_balancer_dns"

# Azure
output "azure_load_balancer_ip"
output "azure_vm_id"

# GCP
output "gcp_load_balancer_ip"
output "gcp_instance_group_id"
```

## 🧪 Testing

### Validate Terraform

```bash
terraform fmt -recursive
terraform validate
```

### Test Individual Modules

```bash
cd modules/aws
terraform init
terraform plan
```

### Test Script Components

```bash
# Source individual component
source scripts/components/git-helpers.sh

# Test function
clone_repo "https://github.com/test/repo" "/tmp/test" "Test Repo"
```

## 📚 Additional Documentation

- [Architecture Details](readme/architecture.md)
- [Deployment Guide](readme/deployment-guide.md)
- [Testing Guide](readme/testing-guide.md)
- [Security Best Practices](readme/security-best-practices.md)

## 🤝 Contributing

When adding new features:

1. Keep modules focused and single-purpose
2. Document all variables and outputs
3. Follow naming conventions (lowercase, underscores)
4. Test modules independently
5. Update README with changes

## 📄 License

This project supports Sustainable Development Goals (SDGs) by enabling easy deployment of Digital Public Goods.
