# Outputs for WebUI module

output "webui_bucket_name" {
  description = "Name of the WebUI hosting bucket"
  value       = aws_s3_bucket.webui.id
}

output "webui_bucket_arn" {
  description = "ARN of the WebUI hosting bucket"
  value       = aws_s3_bucket.webui.arn
}

output "webui_bucket_website_endpoint" {
  description = "Website endpoint for the WebUI bucket"
  value       = aws_s3_bucket_website_configuration.webui.website_endpoint
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.webui.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = aws_cloudfront_distribution.webui.domain_name
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.webui.arn
}
