# Variables for WebUI IAM module

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "data_source_bucket_arn" {
  description = "ARN of the S3 data source bucket for document uploads"
  type        = string
}

variable "data_source_bucket_name" {
  description = "Name of the S3 data source bucket for document uploads"
  type        = string
}

variable "knowledge_base_id" {
  description = "ID of the Bedrock Knowledge Base"
  type        = string
}

variable "knowledge_base_arn" {
  description = "ARN of the Bedrock Knowledge Base"
  type        = string
}

variable "data_source_id" {
  description = "ID of the Bedrock Knowledge Base data source"
  type        = string
}

variable "cognito_identity_pool_id" {
  description = "Cognito Identity Pool ID for WebUI authentication (optional)"
  type        = string
  default     = ""
}

variable "enable_cognito_auth" {
  description = "Enable Cognito authentication for WebUI users"
  type        = bool
  default     = false
}
