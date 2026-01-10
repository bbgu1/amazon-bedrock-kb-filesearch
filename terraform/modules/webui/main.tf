# WebUI hosting infrastructure (optional deployment)
# By default, WebUI runs locally. Deploy this module for production hosting.

# WebUI hosting bucket - for static website
resource "aws_s3_bucket" "webui" {
  bucket = "${var.name_prefix}-webui"

  tags = {
    Name = "${var.name_prefix}-webui"
  }
}

# Enable static website hosting for WebUI bucket
resource "aws_s3_bucket_website_configuration" "webui" {
  bucket = aws_s3_bucket.webui.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html" # For SPA routing
  }
}

# Enable encryption for WebUI bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "webui" {
  bucket = aws_s3_bucket.webui.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public access configuration for WebUI bucket (will be accessed via CloudFront)
resource "aws_s3_bucket_public_access_block" "webui" {
  bucket = aws_s3_bucket.webui.id

  block_public_acls       = true
  block_public_policy     = false # Allow bucket policy for CloudFront
  ignore_public_acls      = true
  restrict_public_buckets = false # Allow bucket policy for CloudFront
}

# CloudFront Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "webui" {
  name                              = "${var.name_prefix}-webui-oac"
  description                       = "OAC for WebUI S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution for WebUI
resource "aws_cloudfront_distribution" "webui" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "CloudFront distribution for Bedrock File Search WebUI"
  price_class         = var.cloudfront_price_class

  origin {
    domain_name              = aws_s3_bucket.webui.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.webui.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.webui.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.webui.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # Custom error response for SPA routing
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    # For custom domain with SSL:
    # acm_certificate_arn      = var.acm_certificate_arn
    # ssl_support_method       = "sni-only"
    # minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name        = "${var.name_prefix}-webui-distribution"
    Environment = var.environment
  }
}

# Bucket policy for WebUI - allow CloudFront access via OAC
resource "aws_s3_bucket_policy" "webui" {
  bucket = aws_s3_bucket.webui.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.webui.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.webui.arn
          }
        }
      }
    ]
  })
}
