# Variables for S3 buckets module

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "enable_lifecycle_policies" {
  description = "Enable lifecycle policies for S3 buckets"
  type        = bool
  default     = false
}

variable "document_expiration_days" {
  description = "Number of days after which documents expire (0 = never expire)"
  type        = number
  default     = 0
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days after which noncurrent versions expire"
  type        = number
  default     = 90
}
