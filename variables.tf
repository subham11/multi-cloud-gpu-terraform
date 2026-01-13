variable "cloud_provider" {
  description = "Choose cloud: aws | azure | gcp"
  type        = string
}

variable "region" {
  description = "Region for the selected cloud"
  type        = string
}

variable "vm_name" {
  description = "Name of the VM"
  type        = string
  default     = "gpu-instance"
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = null
}

# Optional: AWS Certificate ARN for HTTPS
variable "aws_certificate_arn" {
  description = "ARN of ACM certificate for AWS ALB HTTPS listener (optional)"
  type        = string
  default     = null
}

# Optional: Azure SSH Public Key
variable "azure_ssh_public_key" {
  description = "SSH public key for Azure VM (optional - will use default if not provided)"
  type        = string
  default     = null
  sensitive   = true
}

# Optional: GCP SSL Certificate
variable "gcp_ssl_certificate_id" {
  description = "GCP SSL certificate ID for HTTPS (optional)"
  type        = string
  default     = null
}

# Git credentials for private repository access
variable "git_username" {
  description = "Git username/email for private repository access"
  type        = string
  default     = ""
  sensitive   = true
}

variable "git_password" {
  description = "Git password/token for private repository access"
  type        = string
  default     = ""
  sensitive   = true
}