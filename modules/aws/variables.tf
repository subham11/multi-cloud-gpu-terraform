# AWS GPU Infrastructure Module
# Manages VPC, networking, compute, and load balancer resources

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
