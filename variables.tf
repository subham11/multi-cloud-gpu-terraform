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

  # ============================================================================
  # Environment Configuration
  # ============================================================================
  variable "environment" {
    description = "Environment name (development, staging, production)"
    type        = string
    default     = "development"
    validation {
      condition     = contains(["development", "staging", "production"], var.environment)
      error_message = "Environment must be development, staging, or production."
    }
  }

  # ============================================================================
  # Resource Tagging
  # ============================================================================
  variable "tags" {
    description = "Common tags to apply to all resources"
    type        = map(string)
    default = {
      ManagedBy = "terraform"
      Project   = "digital-public-goods"
    }
  }

  # ============================================================================
  # Network Configuration
  # ============================================================================
  variable "vpc_cidr" {
    description = "CIDR block for VPC"
    type        = string
    default     = "10.0.0.0/16"
  }

  variable "public_subnet_cidr" {
    description = "CIDR block for public subnet"
    type        = string
    default     = "10.0.1.0/24"
  }

  variable "private_subnet_cidr" {
    description = "CIDR block for private subnet"
    type        = string
    default     = "10.0.2.0/24"
  }

  variable "enable_nat_gateway" {
    description = "Enable NAT gateway for private subnets"
    type        = bool
    default     = false
  }

  variable "enable_vpc_flow_logs" {
    description = "Enable VPC flow logs"
    type        = bool
    default     = false
  }

  # ============================================================================
  # Security Configuration
  # ============================================================================
  variable "allowed_ssh_cidrs" {
    description = "List of CIDR blocks allowed to SSH"
    type        = list(string)
    default     = ["0.0.0.0/0"]
  }

  variable "enable_ssl" {
    description = "Enable SSL/TLS on load balancer"
    type        = bool
    default     = false
  }

  variable "enable_waf" {
    description = "Enable Web Application Firewall"
    type        = bool
    default     = false
  }

  # ============================================================================
  # Auto-scaling Configuration
  # ============================================================================
  variable "enable_autoscaling" {
    description = "Enable auto-scaling for instances"
    type        = bool
    default     = false
  }

  variable "min_instances" {
    description = "Minimum number of instances in auto-scaling group"
    type        = number
    default     = 1
  }

  variable "max_instances" {
    description = "Maximum number of instances in auto-scaling group"
    type        = number
    default     = 5
  }

  variable "instance_count" {
    description = "Number of instances to create"
    type        = number
    default     = 1
  }

  # ============================================================================
  # Monitoring and Backup
  # ============================================================================
  variable "enable_monitoring" {
    description = "Enable detailed monitoring"
    type        = bool
    default     = false
  }

  variable "enable_backups" {
    description = "Enable automated backups"
    type        = bool
    default     = false
  }

  variable "backup_retention" {
    description = "Number of days to retain backups"
    type        = number
    default     = 7
  }

  # ============================================================================
  # High Availability
  # ============================================================================
  variable "enable_multi_az" {
    description = "Enable multi-AZ deployment"
    type        = bool
    default     = false
  }

  variable "enable_cross_region_backup" {
    description = "Enable cross-region backup replication"
    type        = bool
    default     = false
  }

  variable "health_check_interval" {
    description = "Health check interval in seconds"
    type        = number
    default     = 30
  }

  variable "unhealthy_threshold" {
    description = "Number of failed health checks before marking unhealthy"
    type        = number
    default     = 2
  }