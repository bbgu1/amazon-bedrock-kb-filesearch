# WebUI Module

This module provisions the infrastructure for hosting the WebUI as a static website on AWS.

## Overview

By default, the WebUI is designed to run locally during development. This module is **optional** and should only be deployed when you want to host the WebUI in AWS for production or demo purposes.

## Resources Created

- **S3 Bucket**: Static website hosting for React application
- **S3 Bucket Policy**: Allows CloudFront access via Origin Access Control
- **CloudFront Distribution**: CDN for global content delivery with HTTPS
- **Origin Access Control (OAC)**: Secure access from CloudFront to S3

## Features

- Static website hosting with SPA routing support
- CloudFront CDN with HTTPS (using default CloudFront certificate)
- Custom error responses for React Router compatibility (404/403 → index.html)
- Gzip compression enabled
- Encryption at rest for S3 bucket
- Origin Access Control for secure S3 access

## Usage

### Local Development (Default)

By default, `deploy_webui = false` in the root module, so this module is not deployed. The WebUI runs locally:

```bash
cd webui
npm install
npm run dev
```

### Production Deployment

To deploy the WebUI to AWS, set `deploy_webui = true`:

```hcl
# In terraform.tfvars or when running terraform apply
deploy_webui = true
```

Then apply the Terraform configuration:

```bash
terraform apply -var="deploy_webui=true"
```

### Deploying WebUI Assets

After the infrastructure is created, build and deploy the WebUI:

```bash
# Build the React app
cd webui
npm run build

# Deploy to S3
aws s3 sync dist/ s3://$(terraform output -raw webui_bucket_name)/

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

## Outputs

- `webui_bucket_name`: S3 bucket name for hosting
- `webui_bucket_website_endpoint`: Direct S3 website endpoint
- `cloudfront_distribution_id`: CloudFront distribution ID for cache invalidation
- `cloudfront_domain_name`: Public URL for accessing the WebUI (e.g., d123456.cloudfront.net)
- `cloudfront_distribution_arn`: CloudFront distribution ARN

## Configuration

### CloudFront Price Class

By default, the module uses `PriceClass_100` (North America and Europe). You can change this:

```hcl
module "webui" {
  source = "./modules/webui"
  
  cloudfront_price_class = "PriceClass_All" # Global distribution
}
```

### Custom Domain (Optional)

To use a custom domain with SSL:

1. Create an ACM certificate in `us-east-1` region
2. Uncomment the `acm_certificate_arn` variable in `variables.tf`
3. Update the `viewer_certificate` block in `main.tf`
4. Create a CNAME record pointing to the CloudFront domain

## Notes

- CloudFront uses Origin Access Control (OAC) instead of legacy Origin Access Identity (OAI)
- Custom error responses redirect 404/403 to index.html for SPA routing
- Default cache TTL is 1 hour (3600 seconds)
- The S3 bucket is not publicly accessible; only CloudFront can access it
- CORS is not needed on the WebUI bucket since it only serves static assets

