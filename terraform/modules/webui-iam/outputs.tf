# Outputs for WebUI IAM module

output "webui_user_role_arn" {
  description = "ARN of the IAM role for WebUI users"
  value       = aws_iam_role.webui_user.arn
}

output "webui_user_role_name" {
  description = "Name of the IAM role for WebUI users"
  value       = aws_iam_role.webui_user.name
}

output "s3_upload_policy_arn" {
  description = "ARN of the S3 upload policy"
  value       = aws_iam_policy.s3_upload.arn
}

output "bedrock_ingestion_policy_arn" {
  description = "ARN of the Bedrock ingestion policy"
  value       = aws_iam_policy.bedrock_ingestion.arn
}

output "bedrock_retrieve_policy_arn" {
  description = "ARN of the Bedrock retrieve policy"
  value       = aws_iam_policy.bedrock_retrieve.arn
}
