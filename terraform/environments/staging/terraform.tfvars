# Staging environment configuration

environment = "staging"
aws_region  = "us-east-1"

# Nova embedding model
nova_model_id = "amazon.nova-embed-multimodal-v1"

# Allowed file types
allowed_file_types = [".txt", ".md", ".pdf", ".png", ".jpg", ".docx", ".xlsx"]

# OpenSearch capacity
opensearch_capacity_units = 4

# API Gateway throttling
api_gateway_throttle_burst_limit = 100
api_gateway_throttle_rate_limit  = 50
