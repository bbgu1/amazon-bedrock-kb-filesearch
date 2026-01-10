# Variables for Bedrock Knowledge Base module

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "nova_model_id" {
  description = "Amazon Nova embedding model ID"
  type        = string
}

variable "opensearch_collection_arn" {
  description = "ARN of the OpenSearch Serverless collection"
  type        = string
}

variable "opensearch_index_name" {
  description = "vector index name"
  type        = string
}

variable "opensearch_collection_endpoint" {
  description = "Endpoint of the OpenSearch Serverless collection"
  type        = string
}

variable "s3_data_source_bucket" {
  description = "S3 bucket name for data source"
  type        = string
}


variable "opensearch_collection_ready" {
  description = "Dummy variable to ensure OpenSearch collection is ready"
  type        = string
  default     = ""
}


variable "supplemental_data_bucket_name" {
  description = "S3 bucket name for supplemental data storage (multi-modal processing)"
  type        = string
}
