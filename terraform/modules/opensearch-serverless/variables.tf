# Variables for OpenSearch Serverless module

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "bedrock_kb_role_arn" {
  description = "ARN of the Bedrock Knowledge Base IAM role for data access policy"
  type        = string
}
