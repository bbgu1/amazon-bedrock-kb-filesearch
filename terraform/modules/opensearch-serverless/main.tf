# OpenSearch Serverless collection for vector storage

# Local variables for shorter names
locals {
  # Shorten names to fit within 32 character limit
  collection_name = "${var.environment}-bfs-vector"
  encryption_policy_name = "${var.environment}-bfs-encrypt"
  network_policy_name = "${var.environment}-bfs-network"
  data_access_policy_name = "${var.environment}-bfs-data"
}

# Encryption policy for the collection
resource "aws_opensearchserverless_security_policy" "encryption" {
  name        = local.encryption_policy_name
  type        = "encryption"
  description = "Encryption policy for Bedrock File Search OpenSearch collection"

  policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection"
        Resource = [
          "collection/${local.collection_name}"
        ]
      }
    ]
    AWSOwnedKey = true
  })
}

# Network policy for the collection
resource "aws_opensearchserverless_security_policy" "network" {
  name        = local.network_policy_name
  type        = "network"
  description = "Network policy for Bedrock File Search OpenSearch collection"

  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/${local.collection_name}"
          ]
        },
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/${local.collection_name}"
          ]
        }
      ]
      AllowFromPublic = true
    }
  ])
}

# Data access policy for Bedrock Knowledge Base and Terraform
resource "aws_opensearchserverless_access_policy" "data_access" {
  name        = local.data_access_policy_name
  type        = "data"
  description = "Data access policy for Bedrock Knowledge Base and Terraform"

  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/${local.collection_name}"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems"
          ]
        },
        {
          ResourceType = "index"
          Resource = [
            "index/${local.collection_name}/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument",
            "aoss:UpdateIndex",
            "aoss:DeleteIndex"
          ]
        }
      ]
      Principal = [
        var.bedrock_kb_role_arn,
        data.aws_caller_identity.current.arn
      ]
    }
  ])
}

# OpenSearch Serverless collection
resource "aws_opensearchserverless_collection" "vector_store" {
  name        = local.collection_name
  type        = "VECTORSEARCH"
  description = "Vector store for Bedrock File Search service with multimodal embeddings"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
    aws_opensearchserverless_access_policy.data_access
  ]

  tags = {
    Name = local.collection_name
  }
}



# Wait for collection to be fully active and access policies to propagate
resource "null_resource" "wait_for_collection" {
  triggers = {
    collection_id = aws_opensearchserverless_collection.vector_store.id
    policy_version = aws_opensearchserverless_access_policy.data_access.policy_version
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for OpenSearch collection to be fully active and access policies to propagate..."
      sleep 90
      echo "Collection should be ready now"
    EOT
  }

  depends_on = [
    aws_opensearchserverless_collection.vector_store,
    aws_opensearchserverless_access_policy.data_access
  ]
}

# Create the vector index for Bedrock Knowledge Base
resource "opensearch_index" "bedrock_vector_index_files" {
  name               = "${var.environment}-bfs-vector-index-files"  # New index name to force recreation
  number_of_shards   = 2
  number_of_replicas = 0
  force_destroy      = true  # Allow destroying index even with documents

  mappings = jsonencode({
    properties = {
      "bedrock-knowledge-base-default-vector" = {
        type      = "knn_vector"
        dimension = 3072
        method = {
          name   = "hnsw"
          engine = "faiss"
        }
      }
      "AMAZON_BEDROCK_TEXT_CHUNK" = {
        type = "text"
      }
      "AMAZON_BEDROCK_METADATA" = {
        type = "text"
      }
      # Metadata fields from .metadata.json files (with underscores)
      "store_id" = {
        type = "text"
        "fields" = {
          "keyword" = {
            "type"          = "keyword"
            "ignore_above"  = 256
          }
        }
      }
      "document_id" = {
        type = "text"
      }
      "filename" = {
        type = "text"
      }
      "content_type" = {
        type = "text"
      }
      "upload_date" = {
        type = "date"
      }
      "file_size" = {
        type = "long"
      }
    }
  })

  index_knn = true

  depends_on = [
    null_resource.wait_for_collection
  ]
}
