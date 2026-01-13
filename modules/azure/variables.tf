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
