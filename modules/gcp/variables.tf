# GCP GPU Infrastructure Module

variable "vm_name" {
  description = "Name prefix for resources"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "g2-standard-16"
}

variable "gpu_type" {
  description = "GPU accelerator type"
  type        = string
  default     = "nvidia-l4"
}

variable "gpu_count" {
  description = "Number of GPUs"
  type        = number
  default     = 1
}

variable "user_data_script" {
  description = "Base64 encoded startup script"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "vpc_cidr" {
  description = "VPC CIDR range"
  type        = string
  default     = "10.2.0.0/16"
}

variable "public_subnets" {
  description = "Map of public subnets"
  type = map(object({
    cidr = string
  }))
  default = {
    "public-a" = { cidr = "10.2.1.0/24" }
    "public-b" = { cidr = "10.2.2.0/24" }
  }
}

variable "private_subnets" {
  description = "Map of private subnets"
  type = map(object({
    cidr = string
  }))
  default = {
    "private-a" = { cidr = "10.2.10.0/24" }
    "private-b" = { cidr = "10.2.11.0/24" }
  }
}

variable "database_subnets" {
  description = "Map of database subnets"
  type = map(object({
    cidr = string
  }))
  default = {
    "database-a" = { cidr = "10.2.20.0/24" }
    "database-b" = { cidr = "10.2.21.0/24" }
  }
}

variable "enable_database_subnet" {
  description = "Enable database subnet tier"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC/subnet flow logs"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDR ranges allowed to SSH"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "labels" {
  description = "Labels applied to GCP resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "multi-cloud-gpu"
  }
}

variable "enable_private_dns_zone" {
  description = "Create private DNS zone bound to the VPC"
  type        = bool
  default     = false
}

variable "private_dns_zone_name" {
  description = "Private DNS zone name (e.g., internal.local)"
  type        = string
  default     = "internal.local"
}
