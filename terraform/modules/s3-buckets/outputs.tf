# Outputs for S3 buckets module

output "data_source_bucket_name" {
  description = "Name of the data source bucket (used for document uploads and Bedrock ingestion)"
  value       = aws_s3_bucket.data_source.id
}

output "data_source_bucket_arn" {
  description = "ARN of the data source bucket"
  value       = aws_s3_bucket.data_source.arn
}

output "supplemental_data_bucket_name" {
  description = "Name of the supplemental data storage bucket for multi-modal processing"
  value       = aws_s3_bucket.supplemental_data.id
}

output "supplemental_data_bucket_arn" {
  description = "ARN of the supplemental data storage bucket"
  value       = aws_s3_bucket.supplemental_data.arn
}
