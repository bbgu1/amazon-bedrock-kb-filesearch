# Lambda Layer Module Outputs

output "layer_arn" {
  description = "ARN of the Lambda layer"
  value       = aws_lambda_layer_version.shared.arn
}

output "layer_version" {
  description = "Version of the Lambda layer"
  value       = aws_lambda_layer_version.shared.version
}
