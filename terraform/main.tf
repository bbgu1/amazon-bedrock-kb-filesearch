# Main Terraform configuration for Bedrock File Search Service

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "bedrock-file-search"
      ManagedBy   = "terraform"
    }
  }
}

# Local variables
locals {
  name_prefix = "${var.environment}-bedrock-file-search"
}

# Lambda Layer module - Shared dependencies for Lambda functions
module "lambda_layer" {
  source = "./modules/lambda-layer"

  environment = var.environment
  name_prefix = local.name_prefix
}

# Store Management API module (DynamoDB + Lambda + API Gateway + IAM)
module "store_management_api" {
  count = var.deploy_store_management_api ? 1 : 0

  source = "./modules/store-management-api"

  environment                   = var.environment
  name_prefix                   = local.name_prefix
  shared_layer_arn              = module.lambda_layer.layer_arn
  enable_point_in_time_recovery = var.enable_dynamodb_pitr
  enable_deletion_protection    = var.enable_dynamodb_deletion_protection
  throttle_burst_limit          = var.api_gateway_throttle_burst_limit
  throttle_rate_limit           = var.api_gateway_throttle_rate_limit
}

# S3 buckets module
module "s3" {
  source = "./modules/s3-buckets"

  environment                        = var.environment
  name_prefix                        = local.name_prefix
  enable_lifecycle_policies          = var.enable_s3_lifecycle_policies
  document_expiration_days           = var.document_expiration_days
  noncurrent_version_expiration_days = var.noncurrent_version_expiration_days
}

# OpenSearch Serverless module
module "opensearch" {
  source = "./modules/opensearch-serverless"

  environment         = var.environment
  name_prefix         = local.name_prefix
  bedrock_kb_role_arn = module.bedrock_kb.bedrock_kb_role_arn
}

# Bedrock Knowledge Base module
module "bedrock_kb" {
  source = "./modules/bedrock-knowledge-base"

  environment                    = var.environment
  name_prefix                    = local.name_prefix
  nova_model_id                  = var.nova_model_id
  opensearch_collection_arn      = module.opensearch.collection_arn
  opensearch_collection_endpoint = module.opensearch.collection_endpoint
  opensearch_collection_ready    = module.opensearch.collection_ready
  opensearch_index_name          = module.opensearch.index_name
  s3_data_source_bucket          = module.s3.data_source_bucket_name
  supplemental_data_bucket_name  = module.s3.supplemental_data_bucket_name
}

# WebUI hosting module (optional - disabled by default for local development)
module "webui" {
  count = var.deploy_webui ? 1 : 0

  source = "./modules/webui"

  environment = var.environment
  name_prefix = local.name_prefix
}

# WebUI IAM module - IAM roles and policies for WebUI client access
module "webui_iam" {
  source = "./modules/webui-iam"

  environment              = var.environment
  name_prefix              = local.name_prefix
  data_source_bucket_arn   = module.s3.data_source_bucket_arn
  data_source_bucket_name  = module.s3.data_source_bucket_name
  knowledge_base_id        = module.bedrock_kb.knowledge_base_id
  knowledge_base_arn       = module.bedrock_kb.knowledge_base_arn
  data_source_id           = module.bedrock_kb.data_source_id
  cognito_identity_pool_id = var.cognito_identity_pool_id
  enable_cognito_auth      = var.enable_cognito_auth
}
