# Variables for development environment

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "nova_model_id" {
  description = "Amazon Nova embedding model ID"
  type        = string
}

variable "allowed_file_types" {
  description = "List of allowed file extensions"
  type        = list(string)
}

variable "opensearch_capacity_units" {
  description = "OpenSearch Serverless capacity units"
  type        = number
}

variable "api_gateway_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
}

variable "api_gateway_throttle_rate_limit" {
  description = "API Gateway throttle rate limit"
  type        = number
}
