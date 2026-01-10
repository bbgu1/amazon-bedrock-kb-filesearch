# Provider configuration for OpenSearch Serverless module

terraform {
  required_providers {
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "~> 2.0"
    }
  }
}

# Data source to get current region
data "aws_region" "current" {}

# Data source to get current caller identity
data "aws_caller_identity" "current" {}

# OpenSearch provider configuration for OpenSearch Serverless
provider "opensearch" {
  url         = aws_opensearchserverless_collection.vector_store.collection_endpoint
  healthcheck = false
  sign_aws_requests = true
  
  aws_region = data.aws_region.current.name
}
