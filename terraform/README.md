# Terraform Infrastructure

This directory contains the Infrastructure as Code (IaC) for the Bedrock Knowledge Base demo.

## Structure

```
terraform/
├── modules/                      # Reusable Terraform modules
│   ├── bedrock-knowledge-base/   # Knowledge Base and data source
│   ├── opensearch-serverless/    # Vector database
│   ├── s3-buckets/               # Document storage
│   ├── store-management-api/     # Lambda + API Gateway
│   ├── lambda-layer/             # Shared Lambda dependencies
│   └── webui-iam/                # IAM roles for WebUI
├── environments/
│   └── dev/                      # Development environment
├── main.tf                       # Root module
├── outputs.tf                    # Output values
└── variables.tf                  # Input variables
```

## Deployment

```bash
cd environments/dev

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Get outputs
terraform output
```

## Key Outputs

After deployment, these outputs are available:

- `aws_region`: AWS region
- `knowledge_base_id`: Bedrock Knowledge Base ID
- `data_source_id`: Data source ID
- `data_source_bucket_name`: S3 bucket for documents
- `api_gateway_endpoint`: Store management API endpoint

## Modules

### bedrock-knowledge-base
Creates Bedrock Knowledge Base with S3 data source, IAM roles, and metadata schema.

### opensearch-serverless
Provisions OpenSearch Serverless collection with vector search configuration.

### s3-buckets
Creates S3 buckets for document storage with versioning, encryption, and CORS.

### store-management-api
Deploys Lambda function and API Gateway for store CRUD operations.

### webui-iam
Creates IAM roles and policies for WebUI to access AWS services.

## Configuration

Edit `environments/dev/terraform.tfvars` to customize:

```hcl
environment = "dev"
aws_region  = "us-east-1"
nova_model_id = "amazon.titan-embed-text-v2:0"
opensearch_capacity_units = 2
```

## Cleanup

```bash
cd environments/dev
terraform destroy
```

See the main [README.md](../README.md) for complete documentation.
