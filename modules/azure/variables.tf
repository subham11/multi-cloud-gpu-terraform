# Azure GPU Infrastructure Module

variable "vm_name" {
  description = "Name prefix for resources"
  type        = string
}

variable "region" {
  description = "Azure region"
  type        = string
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_NV36ads_A10_v5"
}

variable "user_data_script" {
  description = "Base64 encoded custom data script"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for admin user"
  type        = string
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "vnet_cidr" {
  description = "Address space for the Virtual Network"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnets" {
  description = "Map of public subnets (CIDR and zone)"
  type = map(object({
    cidr = string
    zone = string
  }))
  default = {
    "public-1" = { cidr = "10.1.1.0/24", zone = "1" }
    "public-2" = { cidr = "10.1.2.0/24", zone = "2" }
  }
}

variable "private_subnets" {
  description = "Map of private subnets (CIDR and zone)"
  type = map(object({
    cidr = string
    zone = string
  }))
  default = {
    "private-1" = { cidr = "10.1.10.0/24", zone = "1" }
    "private-2" = { cidr = "10.1.11.0/24", zone = "2" }
  }
}

variable "database_subnets" {
  description = "Map of database subnets (CIDR and zone)"
  type = map(object({
    cidr = string
    zone = string
  }))
  default = {
    "database-1" = { cidr = "10.1.20.0/24", zone = "1" }
    "database-2" = { cidr = "10.1.21.0/24", zone = "2" }
  }
}

variable "enable_database_subnet" {
  description = "Enable dedicated database subnet tier"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Provision NAT Gateway for private subnet outbound internet access"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable NSG flow logs for monitoring"
  type        = bool
  default     = true
}

variable "enable_private_dns_zone" {
  description = "Create private DNS zone linked to VNet"
  type        = bool
  default     = false
}

variable "private_dns_zone_name" {
  description = "Private DNS zone name"
  type        = string
  default     = "internal.local"
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "tags" {
  description = "Tags applied to all Azure resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Project   = "multi-cloud-gpu"
  }
}
