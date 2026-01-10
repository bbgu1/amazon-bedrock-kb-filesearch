#!/bin/bash

# WebUI Deployment Script
# This script builds and deploys the WebUI to S3 and invalidates CloudFront cache

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if required commands are available
command -v npm >/dev/null 2>&1 || { echo -e "${RED}Error: npm is required but not installed.${NC}" >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo -e "${RED}Error: AWS CLI is required but not installed.${NC}" >&2; exit 1; }

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WEBUI_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
TERRAFORM_DIR="$( cd "$WEBUI_DIR/../terraform" && pwd )"

echo -e "${GREEN}=== Bedrock File Search WebUI Deployment ===${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "$WEBUI_DIR/package.json" ]; then
    echo -e "${RED}Error: package.json not found. Are you in the webui directory?${NC}"
    exit 1
fi

# Get S3 bucket name from Terraform output
echo -e "${YELLOW}Getting S3 bucket name from Terraform...${NC}"
cd "$TERRAFORM_DIR"
BUCKET_NAME=$(terraform output -raw webui_bucket_name 2>/dev/null)

if [ -z "$BUCKET_NAME" ] || [ "$BUCKET_NAME" = "null" ]; then
    echo -e "${RED}Error: Could not get webui_bucket_name from Terraform outputs.${NC}"
    echo -e "${YELLOW}Make sure you have deployed the WebUI module with deploy_webui=true${NC}"
    exit 1
fi

echo -e "${GREEN}✓ S3 Bucket: $BUCKET_NAME${NC}"

# Get CloudFront distribution ID
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null)

if [ -z "$DISTRIBUTION_ID" ] || [ "$DISTRIBUTION_ID" = "null" ]; then
    echo -e "${YELLOW}Warning: Could not get CloudFront distribution ID. Cache invalidation will be skipped.${NC}"
fi

# Build the application
echo ""
echo -e "${YELLOW}Building WebUI application...${NC}"
cd "$WEBUI_DIR"
npm run build

if [ ! -d "$WEBUI_DIR/dist" ]; then
    echo -e "${RED}Error: Build directory not found. Build may have failed.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build completed${NC}"

# Sync to S3
echo ""
echo -e "${YELLOW}Uploading files to S3...${NC}"
aws s3 sync dist/ "s3://$BUCKET_NAME/" --delete

echo -e "${GREEN}✓ Files uploaded to S3${NC}"

# Invalidate CloudFront cache
if [ -n "$DISTRIBUTION_ID" ] && [ "$DISTRIBUTION_ID" != "null" ]; then
    echo ""
    echo -e "${YELLOW}Invalidating CloudFront cache...${NC}"
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id "$DISTRIBUTION_ID" \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    
    echo -e "${GREEN}✓ CloudFront invalidation created: $INVALIDATION_ID${NC}"
    echo -e "${YELLOW}Note: Cache invalidation may take a few minutes to complete${NC}"
fi

# Get CloudFront domain name
CLOUDFRONT_DOMAIN=$(cd "$TERRAFORM_DIR" && terraform output -raw cloudfront_domain_name 2>/dev/null)

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo -e "WebUI is now available at:"
if [ -n "$CLOUDFRONT_DOMAIN" ] && [ "$CLOUDFRONT_DOMAIN" != "null" ]; then
    echo -e "${GREEN}  https://$CLOUDFRONT_DOMAIN${NC}"
else
    echo -e "${YELLOW}  CloudFront domain not available${NC}"
fi
echo ""
