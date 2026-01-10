# Outputs for Bedrock File Search Service

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL for Store Management API"
  value       = var.deploy_store_management_api ? module.store_management_api[0].api_endpoint : null
}

output "store_table_name" {
  description = "DynamoDB table name for store metadata"
  value       = var.deploy_store_management_api ? module.store_management_api[0].dynamodb_table_name : null
}

output "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID"
  value       = module.bedrock_kb.knowledge_base_id
}

output "data_source_id" {
  description = "Bedrock Knowledge Base Data Source ID"
  value       = module.bedrock_kb.data_source_id
}

output "data_source_bucket_name" {
  description = "S3 bucket name for document uploads and Bedrock data source"
  value       = module.s3.data_source_bucket_name
}

output "supplemental_data_bucket_name" {
  description = "S3 bucket name for supplemental data storage (multi-modal processing)"
  value       = module.s3.supplemental_data_bucket_name
}

output "opensearch_collection_endpoint" {
  description = "OpenSearch Serverless collection endpoint"
  value       = module.opensearch.collection_endpoint
}

output "webui_bucket_name" {
  description = "S3 bucket name for WebUI hosting (only if deploy_webui is true)"
  value       = var.deploy_webui ? module.webui[0].webui_bucket_name : null
}

output "webui_bucket_website_endpoint" {
  description = "Website endpoint for WebUI bucket (only if deploy_webui is true)"
  value       = var.deploy_webui ? module.webui[0].webui_bucket_website_endpoint : null
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for WebUI (placeholder, only if deploy_webui is true)"
  value       = var.deploy_webui ? module.webui[0].cloudfront_distribution_id : null
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name for WebUI (placeholder, only if deploy_webui is true)"
  value       = var.deploy_webui ? module.webui[0].cloudfront_domain_name : null
}

# ============================================================================
# WebUI IAM Outputs
# ============================================================================

output "webui_user_role_arn" {
  description = "ARN of the IAM role for WebUI users"
  value       = module.webui_iam.webui_user_role_arn
}

output "webui_user_role_name" {
  description = "Name of the IAM role for WebUI users"
  value       = module.webui_iam.webui_user_role_name
}

output "s3_upload_policy_arn" {
  description = "ARN of the S3 upload policy for WebUI users"
  value       = module.webui_iam.s3_upload_policy_arn
}

output "bedrock_ingestion_policy_arn" {
  description = "ARN of the Bedrock ingestion policy for WebUI users"
  value       = module.webui_iam.bedrock_ingestion_policy_arn
}

output "bedrock_retrieve_policy_arn" {
  description = "ARN of the Bedrock retrieve policy for WebUI users"
  value       = module.webui_iam.bedrock_retrieve_policy_arn
}
