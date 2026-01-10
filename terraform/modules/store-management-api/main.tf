# Store Management API Module
# Provides CRUD operations for store entities with DynamoDB, Lambda, and API Gateway

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================================
# DynamoDB Table for Store Metadata
# ============================================================================

resource "aws_dynamodb_table" "stores" {
  name         = "${var.name_prefix}-stores"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "store_id"

  attribute {
    name = "store_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  deletion_protection_enabled = var.enable_deletion_protection

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.name_prefix}-stores"
    Environment = var.environment
  }
}

# ============================================================================
# Lambda Function Package
# ============================================================================

# Archive the Lambda function code
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/store-management"
  output_path = "${path.module}/.terraform/tmp/store-management-lambda.zip"
}

# ============================================================================
# CloudWatch Logs
# ============================================================================

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name_prefix}-store-management"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.name_prefix}-store-management-logs"
    Environment = var.environment
  }
}

# ============================================================================
# IAM Role and Policy for Lambda
# ============================================================================

resource "aws_iam_role" "lambda" {
  name = "${var.name_prefix}-store-management-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.name_prefix}-store-management-lambda-role"
    Environment = var.environment
  }
}

# CloudWatch Logs policy
resource "aws_iam_role_policy" "lambda_logs" {
  name = "${var.name_prefix}-lambda-logs-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.name_prefix}-store-management:*"
      }
    ]
  })
}

# DynamoDB access policy
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.name_prefix}-lambda-dynamodb-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.stores.arn
      }
    ]
  })
}

# ============================================================================
# Lambda Function
# ============================================================================

resource "aws_lambda_function" "store_management" {
  filename         = data.archive_file.lambda_package.output_path
  function_name    = "${var.name_prefix}-store-management"
  role             = aws_iam_role.lambda.arn
  handler          = "handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256

  layers = [var.shared_layer_arn]

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.stores.name
      LOG_LEVEL           = var.log_level
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.lambda_logs,
    aws_iam_role_policy.lambda_dynamodb
  ]

  tags = {
    Name        = "${var.name_prefix}-store-management"
    Environment = var.environment
  }
}


# ============================================================================
# API Gateway REST API
# ============================================================================

resource "aws_api_gateway_rest_api" "store_management" {
  name        = "${var.name_prefix}-store-management-api"
  description = "API Gateway for Store Management operations"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "${var.name_prefix}-store-management-api"
    Environment = var.environment
  }
}

# /stores resource
resource "aws_api_gateway_resource" "stores" {
  rest_api_id = aws_api_gateway_rest_api.store_management.id
  parent_id   = aws_api_gateway_rest_api.store_management.root_resource_id
  path_part   = "stores"
}

# /stores/{store_id} resource
resource "aws_api_gateway_resource" "store_id" {
  rest_api_id = aws_api_gateway_rest_api.store_management.id
  parent_id   = aws_api_gateway_resource.stores.id
  path_part   = "{store_id}"
}

# ============================================================================
# API Gateway Methods - POST /stores
# ============================================================================

resource "aws_api_gateway_method" "post_stores" {
  rest_api_id   = aws_api_gateway_rest_api.store_management.id
  resource_id   = aws_api_gateway_resource.stores.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_stores" {
  rest_api_id             = aws_api_gateway_rest_api.store_management.id
  resource_id             = aws_api_gateway_resource.stores.id
  http_method             = aws_api_gateway_method.post_stores.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.store_management.invoke_arn
}

# ============================================================================
# API Gateway Methods - GET /stores/{store_id}
# ============================================================================

resource "aws_api_gateway_method" "get_store" {
  rest_api_id   = aws_api_gateway_rest_api.store_management.id
  resource_id   = aws_api_gateway_resource.store_id.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.store_id" = true
  }
}

resource "aws_api_gateway_integration" "get_store" {
  rest_api_id             = aws_api_gateway_rest_api.store_management.id
  resource_id             = aws_api_gateway_resource.store_id.id
  http_method             = aws_api_gateway_method.get_store.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.store_management.invoke_arn
}

# ============================================================================
# API Gateway Methods - PUT /stores/{store_id}
# ============================================================================

resource "aws_api_gateway_method" "put_store" {
  rest_api_id   = aws_api_gateway_rest_api.store_management.id
  resource_id   = aws_api_gateway_resource.store_id.id
  http_method   = "PUT"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.store_id" = true
  }
}

resource "aws_api_gateway_integration" "put_store" {
  rest_api_id             = aws_api_gateway_rest_api.store_management.id
  resource_id             = aws_api_gateway_resource.store_id.id
  http_method             = aws_api_gateway_method.put_store.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.store_management.invoke_arn
}

# ============================================================================
# API Gateway Methods - DELETE /stores/{store_id}
# ============================================================================

resource "aws_api_gateway_method" "delete_store" {
  rest_api_id   = aws_api_gateway_rest_api.store_management.id
  resource_id   = aws_api_gateway_resource.store_id.id
  http_method   = "DELETE"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.store_id" = true
  }
}

resource "aws_api_gateway_integration" "delete_store" {
  rest_api_id             = aws_api_gateway_rest_api.store_management.id
  resource_id             = aws_api_gateway_resource.store_id.id
  http_method             = aws_api_gateway_method.delete_store.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.store_management.invoke_arn
}

# ============================================================================
# CORS Configuration
# ============================================================================

# OPTIONS method for /stores
resource "aws_api_gateway_method" "options_stores" {
  rest_api_id   = aws_api_gateway_rest_api.store_management.id
  resource_id   = aws_api_gateway_resource.stores.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_stores" {
  rest_api_id = aws_api_gateway_rest_api.store_management.id
  resource_id = aws_api_gateway_resource.stores.id
  http_method = aws_api_gateway_method.options_stores.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_stores" {
  rest_api_id = aws_api_gateway_rest_api.store_management.id
  resource_id = aws_api_gateway_resource.stores.id
  http_method = aws_api_gateway_method.options_stores.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "options_stores" {
  rest_api_id = aws_api_gateway_rest_api.store_management.id
  resource_id = aws_api_gateway_resource.stores.id
  http_method = aws_api_gateway_method.options_stores.http_method
  status_code = aws_api_gateway_method_response.options_stores.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.options_stores]
}

# OPTIONS method for /stores/{store_id}
resource "aws_api_gateway_method" "options_store_id" {
  rest_api_id   = aws_api_gateway_rest_api.store_management.id
  resource_id   = aws_api_gateway_resource.store_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_store_id" {
  rest_api_id = aws_api_gateway_rest_api.store_management.id
  resource_id = aws_api_gateway_resource.store_id.id
  http_method = aws_api_gateway_method.options_store_id.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_store_id" {
  rest_api_id = aws_api_gateway_rest_api.store_management.id
  resource_id = aws_api_gateway_resource.store_id.id
  http_method = aws_api_gateway_method.options_store_id.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "options_store_id" {
  rest_api_id = aws_api_gateway_rest_api.store_management.id
  resource_id = aws_api_gateway_resource.store_id.id
  http_method = aws_api_gateway_method.options_store_id.http_method
  status_code = aws_api_gateway_method_response.options_store_id.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.options_store_id]
}

# ============================================================================
# API Gateway Deployment and Stage
# ============================================================================

resource "aws_api_gateway_deployment" "store_management" {
  rest_api_id = aws_api_gateway_rest_api.store_management.id

  depends_on = [
    aws_api_gateway_integration.post_stores,
    aws_api_gateway_integration.get_store,
    aws_api_gateway_integration.put_store,
    aws_api_gateway_integration.delete_store,
    aws_api_gateway_integration.options_stores,
    aws_api_gateway_integration.options_store_id
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "store_management" {
  deployment_id = aws_api_gateway_deployment.store_management.id
  rest_api_id   = aws_api_gateway_rest_api.store_management.id
  stage_name    = var.environment

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name        = "${var.name_prefix}-store-management-stage"
    Environment = var.environment
  }
}

# Method settings for throttling
resource "aws_api_gateway_method_settings" "store_management" {
  rest_api_id = aws_api_gateway_rest_api.store_management.id
  stage_name  = aws_api_gateway_stage.store_management.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = var.throttle_burst_limit
    throttling_rate_limit  = var.throttle_rate_limit
    logging_level          = "INFO"
    data_trace_enabled     = true
    metrics_enabled        = true
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.name_prefix}-store-management"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.name_prefix}-api-gateway-logs"
    Environment = var.environment
  }
}

# API Gateway Account (for CloudWatch Logs)
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${var.name_prefix}-api-gateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.name_prefix}-api-gateway-cloudwatch-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Update Lambda permission to use the correct API Gateway execution ARN
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.store_management.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.store_management.execution_arn}/*/*"
}
