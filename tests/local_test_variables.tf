# Local Testing Variables
# Use these to test configurations without cloud credentials

variable "enable_local_testing" {
  description = "Enable local testing mode (mock resources)"
  type        = bool
  default     = false
}

variable "test_mode" {
  description = "Test mode for validation"
  type        = bool
  default     = true
}

variable "aws_endpoint_override" {
  description = "AWS endpoint override for LocalStack"
  type        = string
  default     = null
}

variable "azure_endpoint_override" {
  description = "Azure endpoint override for Azurite"
  type        = string
  default     = null
}
