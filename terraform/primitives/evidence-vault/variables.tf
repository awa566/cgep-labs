variable "project_name" {
  description = "Prefix for the vault's bucket name."
  type        = string
  default     = "cgep-lab"
}

variable "lock_mode" {
  description = "GOVERNANCE for lab work (admins can override to clean up); COMPLIANCE for real evidence (nobody can delete until retention expires)."
  type        = string
  default     = "GOVERNANCE"

  validation {
    condition     = contains(["GOVERNANCE", "COMPLIANCE"], var.lock_mode)
    error_message = "lock_mode must be GOVERNANCE or COMPLIANCE."
  }
}

variable "retention_days" {
  description = "Days each uploaded object is locked against deletion or overwrite."
  type        = number
  default     = 1
}
