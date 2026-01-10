# Outputs for OpenSearch Serverless module

output "collection_arn" {
  description = "ARN of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.vector_store.arn
}

output "collection_endpoint" {
  description = "Endpoint of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.vector_store.collection_endpoint
}

output "collection_id" {
  description = "ID of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.vector_store.id
}

output "collection_name" {
  description = "Name of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.vector_store.name
}

output "index_name" {
  description = "Name of the vector index for Bedrock Knowledge Base"
  value       = opensearch_index.bedrock_vector_index_files.name
}

output "vector_field_name" {
  description = "Name of the vector field in the index"
  value       = "bedrock-knowledge-base-default-vector"
}

output "text_field_name" {
  description = "Name of the text field in the index"
  value       = "AMAZON_BEDROCK_TEXT_CHUNK"
}

output "metadata_field_name" {
  description = "Name of the metadata field in the index"
  value       = "AMAZON_BEDROCK_METADATA"
}


output "collection_ready" {
  description = "Dummy output to ensure collection is ready before Knowledge Base creation"
  value       = opensearch_index.bedrock_vector_index_files.id
}
