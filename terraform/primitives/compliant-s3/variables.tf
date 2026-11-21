variable "project_name" {
  description = "Lowercase project name used in bucket names (3-21 characters, starts with a letter)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.project_name))
    error_message = "project_name must be 3-21 characters, lowercase letters, numbers or hyphens, and start with a letter."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "bucket_suffix" {
  description = "Optional manual suffix for bucket names. Leave empty to generate a random one."
  type        = string
  default     = ""
}
