#!/bin/bash

# Generate .env file from Terraform outputs
# This script reads Terraform outputs and creates a .env file for the WebUI

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WEBUI_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
TERRAFORM_DIR="$( cd "$WEBUI_DIR/../terraform" && pwd )"

echo -e "${GREEN}=== Generating WebUI .env file ===${NC}"
echo ""

# Check if Terraform directory exists
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo -e "${RED}Error: Terraform directory not found at $TERRAFORM_DIR${NC}"
    exit 1
fi

# Get Terraform outputs
cd "$TERRAFORM_DIR"

echo -e "${YELLOW}Reading Terraform outputs...${NC}"

AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")
KNOWLEDGE_BASE_ID=$(terraform output -raw knowledge_base_id 2>/dev/null)
DATA_SOURCE_ID=$(terraform output -raw data_source_id 2>/dev/null)
BEDROCK_AGENT_ID=$(terraform output -raw bedrock_agent_id 2>/dev/null)
BEDROCK_AGENT_ALIAS_ID=$(terraform output -raw bedrock_agent_alias_id 2>/dev/null)
DATA_SOURCE_BUCKET=$(terraform output -raw data_source_bucket_name 2>/dev/null)
API_ENDPOINT=$(terraform output -raw api_gateway_endpoint 2>/dev/null)

# Validate required outputs
MISSING_OUTPUTS=()

if [ -z "$KNOWLEDGE_BASE_ID" ] || [ "$KNOWLEDGE_BASE_ID" = "null" ]; then
    MISSING_OUTPUTS+=("knowledge_base_id")
fi

if [ -z "$DATA_SOURCE_ID" ] || [ "$DATA_SOURCE_ID" = "null" ]; then
    MISSING_OUTPUTS+=("data_source_id")
fi

if [ -z "$BEDROCK_AGENT_ID" ] || [ "$BEDROCK_AGENT_ID" = "null" ]; then
    MISSING_OUTPUTS+=("bedrock_agent_id")
fi

if [ -z "$BEDROCK_AGENT_ALIAS_ID" ] || [ "$BEDROCK_AGENT_ALIAS_ID" = "null" ]; then
    MISSING_OUTPUTS+=("bedrock_agent_alias_id")
fi

if [ -z "$DATA_SOURCE_BUCKET" ] || [ "$DATA_SOURCE_BUCKET" = "null" ]; then
    MISSING_OUTPUTS+=("data_source_bucket_name")
fi

if [ -z "$API_ENDPOINT" ] || [ "$API_ENDPOINT" = "null" ]; then
    MISSING_OUTPUTS+=("api_gateway_endpoint")
fi

if [ ${#MISSING_OUTPUTS[@]} -gt 0 ]; then
    echo -e "${RED}Error: Missing required Terraform outputs:${NC}"
    for output in "${MISSING_OUTPUTS[@]}"; do
        echo -e "${RED}  - $output${NC}"
    done
    echo ""
    echo -e "${YELLOW}Make sure you have applied the Terraform configuration first.${NC}"
    exit 1
fi

# Create .env file
ENV_FILE="$WEBUI_DIR/.env"

echo -e "${YELLOW}Creating .env file at $ENV_FILE${NC}"

cat > "$ENV_FILE" << EOF
# AWS Configuration
VITE_AWS_REGION=$AWS_REGION

# AWS Resource IDs (from Terraform outputs)
VITE_KNOWLEDGE_BASE_ID=$KNOWLEDGE_BASE_ID
VITE_DATA_SOURCE_ID=$DATA_SOURCE_ID
VITE_BEDROCK_AGENT_ID=$BEDROCK_AGENT_ID
VITE_BEDROCK_AGENT_ALIAS_ID=$BEDROCK_AGENT_ALIAS_ID
VITE_DATA_SOURCE_BUCKET_NAME=$DATA_SOURCE_BUCKET
VITE_API_GATEWAY_ENDPOINT=$API_ENDPOINT

# AWS Credentials (for local development)
# Use AWS CLI configured credentials or set these manually:
# VITE_AWS_ACCESS_KEY_ID=your-access-key
# VITE_AWS_SECRET_ACCESS_KEY=your-secret-key
EOF

echo -e "${GREEN}✓ .env file created successfully${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo -e "  Region: $AWS_REGION"
echo -e "  Knowledge Base ID: $KNOWLEDGE_BASE_ID"
echo -e "  Data Source ID: $DATA_SOURCE_ID"
echo -e "  Bedrock Agent ID: $BEDROCK_AGENT_ID"
echo -e "  Agent Alias ID: $BEDROCK_AGENT_ALIAS_ID"
echo -e "  Data Source Bucket: $DATA_SOURCE_BUCKET"
echo -e "  API Endpoint: $API_ENDPOINT"
echo ""
echo -e "${YELLOW}Note: For local development, you may need to add AWS credentials to .env${NC}"
echo -e "${YELLOW}      or use AWS CLI configured credentials.${NC}"
echo ""
