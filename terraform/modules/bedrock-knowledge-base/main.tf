# Bedrock Knowledge Base configuration
# This is a placeholder - will be implemented in task 5

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================================
# IAM Role and Policy for Bedrock Knowledge Base
# ============================================================================

resource "aws_iam_role" "bedrock_kb" {
  name = "${var.name_prefix}-bedrock-kb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-bedrock-kb-role"
  }
}

resource "aws_iam_role_policy" "bedrock_kb" {
  name = "${var.name_prefix}-bedrock-kb-policy"
  role = aws_iam_role.bedrock_kb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll"
        ]
        Resource = var.opensearch_collection_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_data_source_bucket}",
          "arn:aws:s3:::${var.s3_data_source_bucket}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.supplemental_data_bucket_name}",
          "arn:aws:s3:::${var.supplemental_data_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/${var.nova_model_id}"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# Bedrock Knowledge Base Resources
# ============================================================================

resource "aws_bedrockagent_knowledge_base" "main" {
  name        = "${var.name_prefix}-knowledge-base"
  description = "Multi-tenant knowledge base for document search with multimodal embeddings"
  role_arn    = aws_iam_role.bedrock_kb.arn

  knowledge_base_configuration {
    type = "VECTOR"

    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/${var.nova_model_id}"
      
      # Supplemental data storage for multi-modal processing
      supplemental_data_storage_configuration {
        storage_location {
          type = "S3"
          s3_location {
            uri = "s3://${var.supplemental_data_bucket_name}/"
          }
        }
      }
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"

    opensearch_serverless_configuration {
      collection_arn    = var.opensearch_collection_arn
      vector_index_name = var.opensearch_index_name

      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }

  tags = {
    Name = "${var.name_prefix}-knowledge-base"
  }

  # Note: Bedrock Knowledge Base will automatically create the OpenSearch index
  # if it doesn't exist. The index name must match vector_index_name above.
  # The index will be created with the field mappings specified in field_mapping.
  # Supplemental data storage is used for multi-modal processing (images, etc.)
}

# S3 Data Source for Knowledge Base
resource "aws_bedrockagent_data_source" "s3" {
  name              = "${var.name_prefix}-s3-data-source"
  description       = "S3 data source for document ingestion"
  knowledge_base_id = aws_bedrockagent_knowledge_base.main.id

  data_source_configuration {
    type = "S3"

    s3_configuration {
      bucket_arn = "arn:aws:s3:::${var.s3_data_source_bucket}"
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "NONE"
    }
    parsing_configuration {
      parsing_strategy = "BEDROCK_FOUNDATION_MODEL"
      bedrock_foundation_model_configuration {
        model_arn = "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/amazon.nova-pro-v1:0"
      }
    }
  }


}

# ============================================================================
# Metadata Field Mappings Documentation
# ============================================================================
# The Knowledge Base uses the following metadata fields for filtering and search:
#
# Core Bedrock Fields (automatically managed):
# - bedrock-knowledge-base-default-vector: Vector embeddings (1024 dimensions for Titan)
# - AMAZON_BEDROCK_TEXT_CHUNK: Document text content
# - AMAZON_BEDROCK_METADATA: Bedrock-managed metadata
#
# Custom Metadata Fields (from .metadata.json files):
# Bedrock reads metadata from <filename>.metadata.json files stored alongside documents.
# Each metadata file must contain a JSON object with a "metadataAttributes" key.
#
# Example metadata file (report.pdf.metadata.json):
# {
#   "metadataAttributes": {
#     "store_id": "store-123",
#     "document_id": "doc-456",
#     "filename": "report.pdf",
#     "content_type": "application/pdf",
#     "upload_date": "2024-12-29T10:30:00Z",
#     "file_size": 12345
#   }
# }
#
# Metadata fields indexed in OpenSearch:
# - store_id (keyword): Required field for tenant isolation - MUST be included in all documents
# - document_id (keyword): Unique identifier for the document
# - filename (keyword): Original filename of the uploaded document
# - content_type (keyword): MIME type of the document (e.g., application/pdf, image/png)
# - upload_date (date): ISO8601 timestamp of when the document was uploaded
# - file_size (long): Size of the file in bytes
#
# These metadata fields are:
# 1. Defined in the OpenSearch index schema (opensearch-serverless module)
# 2. Populated via .metadata.json files uploaded alongside documents
# 3. Used for filtering search results by store_id to enforce tenant isolation
# 4. Accessible in search results for display and reference
#
# Usage in search queries:
# - Filter by store_id: { "equals": { "key": "store_id", "value": "store-123" } }
# - Filter by content_type: { "equals": { "key": "content_type", "value": "application/pdf" } }
# - Date range filter: { "greaterThan": { "key": "upload_date", "value": "2024-01-01" } }
# ============================================================================

# Local file documenting the metadata schema
resource "local_file" "metadata_schema" {
  filename = "${path.module}/metadata_schema.json"
  content = jsonencode({
    description = "Metadata schema for Bedrock Knowledge Base documents"
    format = "Metadata files must be named <document-filename>.metadata.json"
    structure = {
      metadataAttributes = {
        description = "Top-level key containing all metadata fields"
        type = "object"
      }
    }
    required_fields = {
      store_id = {
        type        = "keyword"
        description = "Tenant identifier for multi-tenant isolation (REQUIRED)"
        example     = "store-abc123"
      }
    }
    optional_fields = {
      document_id = {
        type        = "keyword"
        description = "Unique identifier for the document"
        example     = "doc-xyz789"
      }
      filename = {
        type        = "keyword"
        description = "Original filename of the document"
        example     = "quarterly-report.pdf"
      }
      content_type = {
        type        = "keyword"
        description = "MIME type of the document"
        example     = "application/pdf"
      }
      upload_date = {
        type        = "date"
        description = "ISO8601 timestamp of document upload"
        example     = "2024-12-29T10:30:00Z"
      }
      file_size = {
        type        = "long"
        description = "Size of the file in bytes"
        example     = 12345
      }
    }
    example_metadata_file = {
      metadataAttributes = {
        store_id = "store-abc123"
        document_id = "doc-xyz789"
        filename = "report.pdf"
        content_type = "application/pdf"
        upload_date = "2024-12-29T10:30:00Z"
        file_size = 12345
      }
    }
    filtering_examples = {
      by_store_id = {
        equals = {
          key   = "store_id"
          value = "store-abc123"
        }
      }
      by_content_type = {
        equals = {
          key   = "content_type"
          value = "application/pdf"
        }
      }
      by_date_range = {
        greaterThan = {
          key   = "upload_date"
          value = "2024-01-01T00:00:00Z"
        }
      }
    }
  })
}
