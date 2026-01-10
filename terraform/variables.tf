# Variables for Bedrock File Search Service

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "nova_model_id" {
  description = "Amazon Nova embedding model ID"
  type        = string
  default     = "amazon.nova-embed-multimodal-v1"
}

variable "allowed_file_types" {
  description = "List of allowed file extensions for document upload"
  type        = list(string)
  default     = [".txt", ".md", ".pdf", ".png", ".jpg", ".docx", ".xlsx"]
}

variable "opensearch_capacity_units" {
  description = "OpenSearch Serverless capacity units"
  type        = number
  default     = 2
}

variable "api_gateway_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 100
}

variable "api_gateway_throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 50
}

variable "deploy_store_management_api" {
  description = "Whether to deploy Store Management API infrastructure (DynamoDB + Lambda + API Gateway)"
  type        = bool
  default     = true
}

variable "enable_dynamodb_pitr" {
  description = "Enable point-in-time recovery for DynamoDB table"
  type        = bool
  default     = false
}

variable "enable_dynamodb_deletion_protection" {
  description = "Enable deletion protection for DynamoDB table"
  type        = bool
  default     = false
}

variable "deploy_webui" {
  description = "Whether to deploy WebUI hosting infrastructure (S3 + CloudFront). Set to false to run WebUI locally."
  type        = bool
  default     = false
}

# ============================================================================
# WebUI IAM Variables
# ============================================================================

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

# ============================================================================
# S3 Lifecycle Variables
# ============================================================================

variable "enable_s3_lifecycle_policies" {
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
