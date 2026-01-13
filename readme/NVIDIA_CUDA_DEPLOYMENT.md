# NVIDIA Drivers & CUDA Auto-Installation

## Overview

This project now includes automatic installation of NVIDIA GPU drivers and CUDA toolkit through cloud-init scripts. The installation happens during instance/VM boot for all three cloud providers.

## Cloud-Init Scripts

### Shared Installation Script

All three cloud providers use the same NVIDIA driver and CUDA installation logic defined in `main.tf`:

```bash
#!/bin/bash
set -e
echo "Starting NVIDIA drivers and CUDA installation..."

# Update system
apt-get update
apt-get upgrade -y

# Install build dependencies
apt-get install -y build-essential curl wget

# Detect NVIDIA GPU
if lspci | grep -i nvidia > /dev/null; then
  echo "NVIDIA GPU detected. Installing drivers and CUDA..."
  
  # Add NVIDIA repository
  curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb -o /tmp/cuda-keyring.deb
  dpkg -i /tmp/cuda-keyring.deb
  apt-get update
  
  # Install NVIDIA drivers and CUDA toolkit
  apt-get install -y cuda-toolkit-12-4 nvidia-driver-550
  
  # Add CUDA to PATH
  echo 'export PATH=/usr/local/cuda/bin:$PATH' >> /etc/profile
  echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> /etc/profile
  
  # Verify installation
  nvidia-smi
  
  echo "NVIDIA drivers and CUDA installation completed successfully!"
else
  echo "No NVIDIA GPU detected. Skipping driver installation."
fi
```

### Cloud Provider Integration

#### AWS (EC2)
- **Integration Method**: `user_data` parameter
- **Encoding**: Base64 encoded by Terraform
- **Location in main.tf**: Line ~214
- **OS**: Ubuntu 22.04 LTS
- **Instance Type**: g5.4xlarge (NVIDIA GPU instances)

```hcl
resource "aws_instance" "gpu" {
  ...
  user_data = local.nvidia_cuda_init_script
  ...
}
```

#### Azure
- **Integration Method**: `custom_data` parameter
- **Encoding**: Base64 encoded by Terraform
- **Location in main.tf**: Line ~391
- **OS**: Ubuntu 22.04 LTS (jammy)
- **VM Size**: Standard_NV36ads_A10_v5 (NVIDIA A10 GPUs)

```hcl
resource "azurerm_linux_virtual_machine" "gpu" {
  ...
  custom_data = local.nvidia_cuda_init_script
  ...
}
```

#### GCP
- **Integration Method**: `metadata_startup_script` parameter
- **Encoding**: Base64 decoded before passing (GCP expects plain text)
- **Location in main.tf**: Line ~481
- **OS**: Debian 12
- **Machine Type**: g2-standard-16 (NVIDIA L4 GPUs)

```hcl
resource "google_compute_instance_template" "gpu" {
  ...
  metadata_startup_script = base64decode(local.nvidia_cuda_init_script)
  ...
}
```

## Installation Timeline

After deployment, the cloud-init script runs during instance/VM boot:

| Cloud | Boot Time | Script Duration | Total Time | Status Check |
|-------|-----------|-----------------|------------|--------------|
| AWS | 2-3 min | 10-15 min | 12-18 min | `nvidia-smi` |
| Azure | 3-5 min | 10-15 min | 13-20 min | `nvidia-smi` |
| GCP | 3-5 min | 10-15 min | 13-20 min | `nvidia-smi` |

## Monitoring Installation Progress

### AWS
```bash
# SSH into instance
ssh -i <key>.pem ec2-user@<instance-ip>

# Monitor cloud-init logs
sudo tail -f /var/log/cloud-init-output.log

# Verify installation
nvidia-smi
```

### Azure
```bash
# SSH into VM
ssh -i <key> azureuser@<vm-ip>

# Monitor cloud-init logs
sudo cat /var/log/cloud-init-output.log

# Verify installation
nvidia-smi
```

### GCP
```bash
# SSH into instance
gcloud compute ssh <instance-name> --zone=<zone>

# Monitor startup script logs
sudo cat /var/log/messages | grep -i nvidia

# Verify installation
nvidia-smi
```

## Deployment Methods

### Method 1: Using deploy.sh (Recommended)

```bash
./deploy.sh
```

The wrapper script will:
1. Check Terraform installation
2. Prompt for cloud provider (aws/azure/gcp)
3. Prompt for region and instance name
4. Initialize and validate Terraform
5. Generate and review the deployment plan
6. Deploy the infrastructure with cloud-init enabled
7. Display endpoints and next steps

### Method 2: Direct Terraform Commands

```bash
# For AWS
terraform apply \
  -var 'cloud_provider=aws' \
  -var 'region=ap-south-1' \
  -var 'vm_name=gpu-server'

# For Azure
terraform apply \
  -var 'cloud_provider=azure' \
  -var 'region=eastus' \
  -var 'vm_name=gpu-server' \
  -var 'azure_ssh_public_key=ssh-rsa AAAAB3...'

# For GCP
terraform apply \
  -var 'cloud_provider=gcp' \
  -var 'region=us-central1' \
  -var 'vm_name=gpu-server' \
  -var 'gcp_project_id=my-project'
```

## Customizing the Installation Script

To modify the NVIDIA driver or CUDA versions, edit the installation script in `main.tf` around line 168:

```hcl
locals {
  nvidia_cuda_init_script = base64encode(<<-EOT
#!/bin/bash
# ... modify the installation commands here ...
EOT
  )
}
```

### Available CUDA Versions

Check available versions at:
- https://developer.nvidia.com/cuda-downloads

Common versions:
- `cuda-toolkit-12-4` - CUDA 12.4
- `cuda-toolkit-12-3` - CUDA 12.3
- `cuda-toolkit-11-8` - CUDA 11.8

### Driver Versions

Current installation uses `nvidia-driver-550`. To use different versions:
- https://www.nvidia.com/Download/driverDetails.aspx/

## Troubleshooting

### Installation Failed

Check cloud-init logs for errors:
```bash
# AWS
sudo cat /var/log/cloud-init-output.log

# Azure
sudo cat /var/log/cloud-init-output.log

# GCP
sudo cat /var/log/messages
```

### GPU Not Detected

Verify GPU attachment:
```bash
# Check if GPU is visible to system
lspci | grep -i nvidia

# Check GPU status
nvidia-smi
```

### CUDA Not in PATH

The script adds CUDA to `/etc/profile`. Reload your shell:
```bash
source /etc/profile
nvcc --version  # Verify CUDA installation
```

### Installation Still Running

Give it more time. The installation can take 10-20 minutes depending on:
- Instance/VM boot time
- Internet connection speed
- System load

Monitor with:
```bash
# AWS/Azure
sudo tail -f /var/log/cloud-init-output.log

# GCP
sudo journalctl -u google-startup-scripts.service -f
```

## Output Variables

After deployment, retrieve endpoints using:

```bash
# AWS load balancer endpoint
terraform output aws_http_endpoint

# Azure load balancer endpoint
terraform output azure_http_endpoint

# GCP load balancer IP
terraform output gcp_load_balancer_ip
```

## Files Modified

- **main.tf**: Added `nvidia_cuda_init_script` local and integrated with all three cloud providers
- **deploy.sh**: New wrapper script for simplified deployment

## Testing

To validate cloud-init integration without deploying:

```bash
# Validate Terraform syntax
terraform validate

# Generate plan to see cloud-init in resources
terraform plan -var 'cloud_provider=aws' -var 'region=ap-south-1' -var 'vm_name=test'
```

## Cleanup

To destroy the deployed infrastructure:

```bash
terraform destroy
```

Or use the deploy script (it will guide you to run this command).

## Best Practices

1. **Wait for Installation**: Always wait for the cloud-init script to complete before using the GPU
2. **Monitor Logs**: Check cloud-init/startup script logs for any errors
3. **Test Connectivity**: SSH into the instance before attempting GPU workloads
4. **Use Load Balancer**: The deployment includes load balancers - use them for production workloads
5. **Update Regularly**: Keep NVIDIA drivers and CUDA updated for security patches

## References

- NVIDIA CUDA Installation: https://developer.nvidia.com/cuda-downloads
- AWS User Data: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
- Azure Custom Data: https://learn.microsoft.com/en-us/azure/virtual-machines/custom-data
- GCP Metadata: https://cloud.google.com/compute/docs/storing-retrieving-metadata
