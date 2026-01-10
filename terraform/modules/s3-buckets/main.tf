# S3 buckets for Bedrock File Search Service
# WebUI hosting has been moved to a separate optional module

# Generate a random ID to ensure globally unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Data source bucket - for document uploads and Bedrock Knowledge Base ingestion
# This bucket is used for:
# - Direct uploads from WebUI
# - Bedrock Knowledge Base data source
# - Document storage with metadata files
resource "aws_s3_bucket" "data_source" {
  bucket = "${var.name_prefix}-data-source-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.name_prefix}-data-source"
  }
}

# Enable versioning for data source bucket
resource "aws_s3_bucket_versioning" "data_source" {
  bucket = aws_s3_bucket.data_source.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption for data source bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "data_source" {
  bucket = aws_s3_bucket.data_source.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access for data source bucket
resource "aws_s3_bucket_public_access_block" "data_source" {
  bucket = aws_s3_bucket.data_source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS configuration for data source bucket (for browser-based uploads)
resource "aws_s3_bucket_cors_configuration" "data_source" {
  bucket = aws_s3_bucket.data_source.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"] # Should be restricted to WebUI domain in production
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# ============================================================================
# S3 Bucket Policies for Authenticated Uploads
# ============================================================================

# Note: Bucket policies with Principal = "*" are blocked by account-level
# S3 Block Public Access settings. Since we're using IAM role-based access
# control (webui-iam module), these bucket policies are not strictly necessary.
# Access is controlled through IAM policies attached to the WebUI user role.

# Bucket policy for Bedrock Knowledge Base access to data source bucket
resource "aws_s3_bucket_policy" "data_source" {
  bucket = aws_s3_bucket.data_source.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBedrockKnowledgeBaseAccess"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data_source.arn,
          "${aws_s3_bucket.data_source.arn}/*"
        ]
      }
    ]
  })
}

# ============================================================================
# S3 Lifecycle Policies (Optional)
# ============================================================================

# Lifecycle policy for data source bucket
resource "aws_s3_bucket_lifecycle_configuration" "data_source" {
  count  = var.enable_lifecycle_policies ? 1 : 0
  bucket = aws_s3_bucket.data_source.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }

  dynamic "rule" {
    for_each = var.document_expiration_days > 0 ? [1] : []
    content {
      id     = "expire-old-documents"
      status = "Enabled"

      expiration {
        days = var.document_expiration_days
      }
    }
  }
}

# ============================================================================
# Supplemental Data Storage Bucket for Multi-Modal Processing
# ============================================================================

# Supplemental data storage bucket - for Bedrock Knowledge Base multi-modal processing
# This bucket stores extracted images and other supplemental data from documents
resource "aws_s3_bucket" "supplemental_data" {
  bucket = "${var.name_prefix}-supplemental-data-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.name_prefix}-supplemental-data"
  }
}

# Enable versioning for supplemental data bucket
resource "aws_s3_bucket_versioning" "supplemental_data" {
  bucket = aws_s3_bucket.supplemental_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption for supplemental data bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "supplemental_data" {
  bucket = aws_s3_bucket.supplemental_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access for supplemental data bucket
resource "aws_s3_bucket_public_access_block" "supplemental_data" {
  bucket = aws_s3_bucket.supplemental_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy for Bedrock Knowledge Base access to supplemental data bucket
resource "aws_s3_bucket_policy" "supplemental_data" {
  bucket = aws_s3_bucket.supplemental_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBedrockKnowledgeBaseAccess"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.supplemental_data.arn,
          "${aws_s3_bucket.supplemental_data.arn}/*"
        ]
      }
    ]
  })
}

# Lifecycle policy for supplemental data bucket
resource "aws_s3_bucket_lifecycle_configuration" "supplemental_data" {
  count  = var.enable_lifecycle_policies ? 1 : 0
  bucket = aws_s3_bucket.supplemental_data.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }

  dynamic "rule" {
    for_each = var.document_expiration_days > 0 ? [1] : []
    content {
      id     = "expire-old-supplemental-data"
      status = "Enabled"

      expiration {
        days = var.document_expiration_days
      }
    }
  }
}
