# OpenSearch Serverless Module

This module provisions an OpenSearch Serverless collection configured for vector search with Amazon Bedrock Knowledge Base.

## Features

- **Vector Search Collection**: Configured for storing and searching document embeddings
- **Encryption**: At-rest and in-transit encryption enabled
- **IAM Access Policies**: Configured for Bedrock Knowledge Base access
- **Index Mapping**: Pre-configured for Nova multimodal embeddings (1024 dimensions)

## Index Schema

The index is configured with the following fields:

### Vector Field
- **bedrock-knowledge-base-default-vector**: knn_vector field with 1024 dimensions for Nova embeddings
  - Uses HNSW algorithm with FAISS engine
  - Optimized for similarity search

### Text Fields
- **AMAZON_BEDROCK_TEXT_CHUNK**: Full text content of document chunks
- **AMAZON_BEDROCK_METADATA**: Bedrock-managed metadata

### Metadata Fields
- **store_id** (keyword): Tenant identifier for multi-tenant isolation
- **filename** (keyword): Original filename
- **content_type** (keyword): MIME type of the document
- **upload_date** (date): Timestamp of document upload
- **document_id** (keyword): Unique document identifier
- **s3_location** (keyword): S3 URI of the source document

## Usage

```hcl
module "opensearch" {
  source = "./modules/opensearch-serverless"

  environment         = var.environment
  name_prefix         = local.name_prefix
  bedrock_kb_role_arn = module.iam.bedrock_kb_role_arn
}
```

## Outputs

- `collection_arn`: ARN of the OpenSearch Serverless collection
- `collection_endpoint`: HTTPS endpoint for the collection
- `collection_id`: Unique identifier for the collection
- `collection_name`: Name of the collection
- `index_name`: Name of the vector index
- `vector_field_name`: Name of the vector field
- `text_field_name`: Name of the text field
- `metadata_field_name`: Name of the metadata field

## Notes

- The index mapping is created as a local file for reference
- Bedrock Knowledge Base will automatically create the index when configured
- The collection uses AWS-owned encryption keys
- Network access is configured to allow public access (secured via IAM)
