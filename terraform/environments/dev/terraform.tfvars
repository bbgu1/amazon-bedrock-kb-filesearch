# Development environment configuration

environment = "dev"
aws_region  = "us-east-1"

# Nova embedding model - Note: Nova multimodal is not yet available in all regions
# Using Titan text embedding as fallback
nova_model_id = "amazon.nova-2-multimodal-embeddings-v1:0"

# Allowed file types
allowed_file_types = [".txt", ".md", ".pdf", ".png", ".jpg", ".docx", ".xlsx"]

# OpenSearch capacity
opensearch_capacity_units = 2

# API Gateway throttling
api_gateway_throttle_burst_limit = 50
api_gateway_throttle_rate_limit  = 25
