# ============================================================================
# AWS GPU Infrastructure Module - Network Variables
# Manages VPC, networking, compute, and load balancer resources
# ============================================================================

variable "vm_name" {
  description = "Name prefix for resources"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "g5.4xlarge"
}

variable "user_data_script" {
  description = "Base64 encoded user data script"
  type        = string
}

variable "git_username" {
  description = "Git username for private repositories"
  type        = string
  default     = ""
  sensitive   = true
}

variable "git_password" {
  description = "Git password for private repositories"
  type        = string
  default     = ""
  sensitive   = true
}

# ============================================================================
# Network Configuration Variables
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "public_subnets" {
  description = "Map of public subnets with CIDR and AZ"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "public-a" = {
      cidr = "10.0.1.0/24"
      az   = "a"
    }
    "public-b" = {
      cidr = "10.0.2.0/24"
      az   = "b"
    }
  }
}

variable "private_subnets" {
  description = "Map of private subnets with CIDR and AZ"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "private-a" = {
      cidr = "10.0.10.0/24"
      az   = "a"
    }
    "private-b" = {
      cidr = "10.0.11.0/24"
      az   = "b"
    }
  }
}

variable "database_subnets" {
  description = "Map of database subnets with CIDR and AZ"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "database-a" = {
      cidr = "10.0.20.0/24"
      az   = "a"
    }
    "database-b" = {
      cidr = "10.0.21.0/24"
      az   = "b"
    }
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets to access internet"
  type        = bool
  default     = false
}

variable "enable_database_subnet" {
  description = "Enable database tier subnets"
  type        = bool
  default     = false
}

variable "enable_nacl" {
  description = "Enable Network ACLs for additional layer of security"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = true
}

variable "flow_logs_traffic_type" {
  description = "Traffic type to log (ACCEPT, REJECT, ALL)"
  type        = string
  default     = "ALL"
  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "Must be ACCEPT, REJECT, or ALL."
  }
}

variable "flow_logs_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 7
  validation {
    condition     = var.flow_logs_retention_days > 0
    error_message = "Retention days must be greater than 0."
  }
}

variable "flow_logs_format" {
  description = "VPC Flow Logs format string"
  type        = string
  default     = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${tcp-flags} $${type} $${pkt-srcaddr} $${pkt-dstaddr} $${region} $${vpc-id} $${flow-logs-id} $${traffic-type} $${subnet-id} $${instance-id} $${interface-type} $${arn} $${http-request} $${http-response} $${http-code}"
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC Endpoints for AWS services (S3, DynamoDB)"
  type        = bool
  default     = false
}

variable "enable_private_hosted_zone" {
  description = "Enable Route53 private hosted zone for DNS"
  type        = bool
  default     = false
}

variable "private_hosted_zone_name" {
  description = "Domain name for private hosted zone (e.g., internal.example.com)"
  type        = string
  default     = "internal.local"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "production"
    Project     = "multi-cloud-gpu"
  }
}
