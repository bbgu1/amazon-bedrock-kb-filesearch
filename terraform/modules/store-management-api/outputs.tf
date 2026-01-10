# Outputs for Store Management API Module

# DynamoDB Outputs
output "dynamodb_table_name" {
  description = "Name of the DynamoDB stores table"
  value       = aws_dynamodb_table.stores.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB stores table"
  value       = aws_dynamodb_table.stores.arn
}

# Lambda Outputs
output "lambda_function_arn" {
  description = "ARN of the Store Management Lambda function"
  value       = aws_lambda_function.store_management.arn
}

output "lambda_function_name" {
  description = "Name of the Store Management Lambda function"
  value       = aws_lambda_function.store_management.function_name
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Store Management Lambda function"
  value       = aws_lambda_function.store_management.invoke_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda.name
}

# API Gateway Outputs
output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.store_management.id
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.store_management.execution_arn
}

output "api_endpoint" {
  description = "URL of the API Gateway endpoint"
  value       = "${aws_api_gateway_stage.store_management.invoke_url}/stores"
}

output "api_stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.store_management.stage_name
}

# CloudWatch Logs Outputs
output "lambda_log_group_name" {
  description = "Name of the Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "api_gateway_log_group_name" {
  description = "Name of the API Gateway CloudWatch log group"
  value       = aws_cloudwatch_log_group.api_gateway.name
}
