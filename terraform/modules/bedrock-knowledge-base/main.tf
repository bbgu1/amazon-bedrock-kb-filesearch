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

