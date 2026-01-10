# Development environment Terraform configuration

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Use the root module
module "bedrock_file_search" {
  source = "../.."

  environment                      = var.environment
  aws_region                       = var.aws_region
  nova_model_id                    = var.nova_model_id
  allowed_file_types               = var.allowed_file_types
  opensearch_capacity_units        = var.opensearch_capacity_units
  api_gateway_throttle_burst_limit = var.api_gateway_throttle_burst_limit
  api_gateway_throttle_rate_limit  = var.api_gateway_throttle_rate_limit
}

# Output values from the module
output "aws_region" {
  value = module.bedrock_file_search.aws_region
}

output "api_gateway_endpoint" {
  value = module.bedrock_file_search.api_gateway_endpoint
}

output "knowledge_base_id" {
  value = module.bedrock_file_search.knowledge_base_id
}

output "data_source_id" {
  value = module.bedrock_file_search.data_source_id
}

output "data_source_bucket_name" {
  value = module.bedrock_file_search.data_source_bucket_name
}

output "supplemental_data_bucket_name" {
  value = module.bedrock_file_search.supplemental_data_bucket_name
}

output "cloudfront_domain_name" {
  value = module.bedrock_file_search.cloudfront_domain_name
}
