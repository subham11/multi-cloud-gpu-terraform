# Common Module - Shared Configuration
# Generates cloud-init scripts for all cloud providers

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

variable "setup_script_path" {
  description = "Path to full-setup.sh script"
  type        = string
  default     = "../scripts/full-setup.sh"
}
