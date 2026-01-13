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
