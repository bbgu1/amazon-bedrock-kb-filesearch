# IAM roles and policies for WebUI client access
# This module creates IAM roles and policies that allow WebUI clients to:
# 1. Upload documents directly to S3 data source bucket
# 2. Trigger ingestion jobs via Bedrock Knowledge Base APIs
# 3. Perform search operations via Bedrock Knowledge Base Retrieve API

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================================
# IAM Role for WebUI Users
# ============================================================================

# IAM role that WebUI users will assume
# This can be used with:
# - Cognito Identity Pool (federated identity)
# - Web Identity Federation (OIDC)
# - Direct IAM user credentials (for testing/demo)
resource "aws_iam_role" "webui_user" {
  name = "${var.name_prefix}-webui-user-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Allow Cognito Identity Pool to assume this role (if enabled)
      var.enable_cognito_auth && var.cognito_identity_pool_id != "" ? [
        {
          Effect = "Allow"
          Principal = {
            Federated = "cognito-identity.amazonaws.com"
          }
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "cognito-identity.amazonaws.com:aud" = var.cognito_identity_pool_id
            }
            "ForAnyValue:StringLike" = {
              "cognito-identity.amazonaws.com:amr" = "authenticated"
            }
          }
        }
      ] : [],
      # Allow direct IAM user assumption (for testing/demo without Cognito)
      [
        {
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          }
          Action = "sts:AssumeRole"
          Condition = {
            StringEquals = {
              "sts:ExternalId" = "${var.name_prefix}-webui-access"
            }
          }
        }
      ]
    )
  })

  tags = {
    Name = "${var.name_prefix}-webui-user-role"
  }
}

# ============================================================================
# S3 Upload Policy
# ============================================================================

# Policy allowing WebUI users to upload documents to S3 data source bucket
# Uploads must follow the pattern: {store_id}/{document_id}/{filename}
resource "aws_iam_policy" "s3_upload" {
  name        = "${var.name_prefix}-webui-s3-upload-policy"
  description = "Allow WebUI users to upload documents to S3 data source bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3PutObject"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${var.data_source_bucket_arn}/*"
        Condition = {
          StringLike = {
            # Enforce store_id prefix pattern: store_id must be at least 3 characters
            "s3:x-amz-meta-store-id" = "*"
          }
        }
      },
      {
        Sid    = "AllowS3ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = var.data_source_bucket_arn
      },
      {
        Sid    = "AllowS3GetObject"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${var.data_source_bucket_arn}/*"
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-webui-s3-upload-policy"
  }
}

# ============================================================================
# Bedrock Ingestion Policy
# ============================================================================

# Policy allowing WebUI users to trigger and monitor ingestion jobs
resource "aws_iam_policy" "bedrock_ingestion" {
  name        = "${var.name_prefix}-webui-bedrock-ingestion-policy"
  description = "Allow WebUI users to start and monitor Bedrock Knowledge Base ingestion jobs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowStartIngestionJob"
        Effect = "Allow"
        Action = [
          "bedrock:StartIngestionJob"
        ]
        Resource = [
          var.knowledge_base_arn,
          "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:knowledge-base/${var.knowledge_base_id}/data-source/${var.data_source_id}"
        ]
      },
      {
        Sid    = "AllowGetIngestionJob"
        Effect = "Allow"
        Action = [
          "bedrock:GetIngestionJob",
          "bedrock:ListIngestionJobs"
        ]
        Resource = [
          var.knowledge_base_arn,
          "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:knowledge-base/${var.knowledge_base_id}/data-source/${var.data_source_id}"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-webui-bedrock-ingestion-policy"
  }
}

# ============================================================================
# Bedrock Retrieve Policy
# ============================================================================

# Policy allowing WebUI users to perform search operations
resource "aws_iam_policy" "bedrock_retrieve" {
  name        = "${var.name_prefix}-webui-bedrock-retrieve-policy"
  description = "Allow WebUI users to retrieve and search documents via Bedrock Knowledge Base"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBedrockRetrieve"
        Effect = "Allow"
        Action = [
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate"
        ]
        Resource = var.knowledge_base_arn
      },
      {
        Sid    = "AllowBedrockInvokeModel"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/*"
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-webui-bedrock-retrieve-policy"
  }
}

# ============================================================================
# Attach Policies to Role
# ============================================================================

resource "aws_iam_role_policy_attachment" "s3_upload" {
  role       = aws_iam_role.webui_user.name
  policy_arn = aws_iam_policy.s3_upload.arn
}

resource "aws_iam_role_policy_attachment" "bedrock_ingestion" {
  role       = aws_iam_role.webui_user.name
  policy_arn = aws_iam_policy.bedrock_ingestion.arn
}

resource "aws_iam_role_policy_attachment" "bedrock_retrieve" {
  role       = aws_iam_role.webui_user.name
  policy_arn = aws_iam_policy.bedrock_retrieve.arn
}
