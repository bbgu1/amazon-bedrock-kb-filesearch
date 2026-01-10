# Amazon Bedrock Knowledge Base Demo

A complete, production-ready example demonstrating Amazon Bedrock Knowledge Base with multi-tenant document management, semantic search, and AI-powered question answering.

## Overview

This solution showcases how to build a scalable, multi-tenant document search system using Amazon Bedrock Knowledge Base. It includes:

- **Multi-tenant document storage** with logical isolation
- **Semantic search** using vector embeddings
- **AI-powered question answering** with Retrieve-and-Generate
- **Web-based UI** for document management and search
- **Infrastructure as Code** using Terraform
- **Serverless architecture** for cost-effective scaling

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────────┐
│                          WebUI (React)                          │
│  - Store Management  - Document Upload  - Search & Q&A         │
└────────────┬────────────────────┬────────────────┬─────────────┘
             │                    │                │
             ▼                    ▼                ▼
    ┌────────────────┐   ┌────────────────┐   ┌──────────────────┐
    │  API Gateway   │   │   S3 Bucket    │   │ Bedrock Agent    │
    │  + Lambda      │   │  (Documents)   │   │    Runtime       │
    └────────┬───────┘   └────────┬───────┘   └────────┬─────────┘
             │                    │                     │
             ▼                    ▼                     ▼
    ┌────────────────┐   ┌────────────────────────────────────────┐
    │   DynamoDB     │   │   Bedrock Knowledge Base               │
    │ (Store Metadata│   │   - Vector Search (Retrieve)           │
    └────────────────┘   │   - Q&A (RetrieveAndGenerate)          │
                         │   - Titan Text Embeddings              │
                         │   - Amazon Nova Pro (Generation)       │
                         └────────────┬───────────────────────────┘
                                      │
                                      ▼
                         ┌────────────────────────┐
                         │  OpenSearch Serverless │
                         │   (Vector Database)    │
                         └────────────────────────┘
```

### Key Features

1. **Multi-Tenant Isolation**
   - Each store has a unique `store_id`
   - Documents are filtered by `store_id` during search
   - Metadata-based isolation (no separate databases)

2. **Document Ingestion**
   - Direct browser upload to S3
   - Automatic metadata file creation (`.metadata.json`)
   - Client-initiated ingestion jobs
   - Support for PDF, DOCX, TXT, images, and more

3. **Search Capabilities**
   - **Semantic Search**: Vector-based similarity search with relevance scores
   - **AI Q&A**: Natural language answers generated from retrieved documents
   - **Citations**: Source attribution for generated responses

4. **Serverless & Managed**
   - No servers to manage
   - Auto-scaling based on demand
   - Pay only for what you use

## Technology Stack

### AWS Services
- **Amazon Bedrock Knowledge Base**: Document indexing and retrieval
- **Amazon Bedrock Runtime**: AI model invocation
- **OpenSearch Serverless**: Vector database
- **AWS Lambda**: Store management API
- **Amazon S3**: Document storage
- **Amazon DynamoDB**: Store metadata
- **Amazon API Gateway**: REST API
- **AWS IAM**: Access control

### Models
- **Embeddings**: Amazon Titan Text Embeddings v2
- **Generation**: Amazon Nova Pro

### Infrastructure
- **Terraform**: Infrastructure as Code
- **React + TypeScript**: Web UI
- **AWS SDK v3**: Direct AWS service calls from browser

## Prerequisites

- AWS Account with Bedrock access enabled
- Terraform >= 1.0
- Node.js >= 18
- AWS CLI configured

## Quick Start

### 1. Deploy Infrastructure

```bash
cd terraform/environments/dev

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy (takes ~5-10 minutes)
terraform apply

# Get outputs
terraform output
```

### 2. Configure WebUI

```bash
cd ../../webui

# Install dependencies
npm install

# Auto-configure from Terraform outputs
(cd ../terraform/environments/dev && terraform refresh && \
 echo "VITE_AWS_REGION=$(terraform output -raw aws_region)" > ../../webui/.env && \
 echo "VITE_KNOWLEDGE_BASE_ID=$(terraform output -raw knowledge_base_id)" >> ../../webui/.env && \
 echo "VITE_DATA_SOURCE_ID=$(terraform output -raw data_source_id)" >> ../../webui/.env && \
 echo "VITE_DATA_SOURCE_BUCKET_NAME=$(terraform output -raw data_source_bucket_name)" >> ../../webui/.env && \
 echo "VITE_API_GATEWAY_ENDPOINT=$(terraform output -raw api_gateway_endpoint)" >> ../../webui/.env && \
 echo "VITE_GENERATION_MODEL_ID=us.amazon.nova-pro-v1:0" >> ../../webui/.env)

# Add your AWS credentials
echo "VITE_AWS_ACCESS_KEY_ID=your_access_key" >> .env
echo "VITE_AWS_SECRET_ACCESS_KEY=your_secret_key" >> .env
```

### 3. Run WebUI

```bash
# Development mode
npm run dev

# Or build and preview
npm run build
npm run preview
```

### 4. Test the Solution

1. **Create a Store**
   - Navigate to the Stores page
   - Click "Create New Store"
   - Enter a store ID and name

2. **Upload Documents**
   - Select your store
   - Go to Upload page
   - Drag and drop files or click to browse
   - Click "Start Ingestion" and wait for completion

3. **Search Documents**
   - Go to Search page
   - Enter a query
   - View results in two tabs:
     - **Retrieved Documents**: Raw search results with scores
     - **Generated Response**: AI-powered answer with citations

## Project Structure

```
.
├── terraform/                    # Infrastructure as Code
│   ├── modules/                  # Reusable Terraform modules
│   │   ├── bedrock-knowledge-base/
│   │   ├── opensearch-serverless/
│   │   ├── s3-buckets/
│   │   ├── store-management-api/
│   │   ├── lambda-layer/
│   │   └── webui-iam/
│   ├── environments/
│   │   └── dev/                  # Development environment
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
│
├── lambda/                       # Lambda function code
│   └── store-management/         # Store CRUD API
│
├── webui/                        # React web application
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── services/             # AWS SDK integrations
│   │   └── types/
│   └── package.json
│
└── README.md                     # This file
```

## How It Works

### Document Upload Flow

1. User uploads file through WebUI
2. File is uploaded directly to S3 with metadata
3. A `.metadata.json` file is created alongside the document
4. User triggers ingestion job via Bedrock API
5. Knowledge Base processes documents and creates embeddings
6. Embeddings are stored in OpenSearch Serverless

### Search Flow

1. User enters search query
2. WebUI calls two APIs in parallel:
   - **Retrieve**: Gets relevant document chunks
   - **RetrieveAndGenerate**: Gets AI-generated answer
3. Results are displayed in tabs:
   - Raw retrieval results with relevance scores
   - Generated response with source citations

### Metadata-Based Filtering

Documents are filtered by `store_id` using metadata:

```json
{
  "metadataAttributes": {
    "store_id": "store-123",
    "document_id": "doc-456",
    "filename": "report.pdf",
    "content_type": "application/pdf",
    "upload_date": "2024-01-10T10:30:00Z"
  }
}
```

Search queries automatically filter by `store_id`:

```typescript
filter: {
  equals: {
    key: 'store_id',
    value: storeId
  }
}
```

## Configuration

### Environment Variables

The WebUI requires these environment variables (`.env`):

```env
VITE_AWS_REGION=us-east-1
VITE_KNOWLEDGE_BASE_ID=<from terraform output>
VITE_DATA_SOURCE_ID=<from terraform output>
VITE_DATA_SOURCE_BUCKET_NAME=<from terraform output>
VITE_API_GATEWAY_ENDPOINT=<from terraform output>
VITE_GENERATION_MODEL_ID=us.amazon.nova-pro-v1:0
VITE_AWS_ACCESS_KEY_ID=<your credentials>
VITE_AWS_SECRET_ACCESS_KEY=<your credentials>
```

### Terraform Variables

Key variables in `terraform/environments/dev/terraform.tfvars`:

```hcl
environment = "dev"
aws_region  = "us-east-1"
nova_model_id = "amazon.titan-embed-text-v2:0"
```

### Supported File Types

- Text: `.txt`, `.md`
- Documents: `.pdf`, `.docx`, `.xlsx`
- Images: `.png`, `.jpg`, `.jpeg`

## Cost Considerations

This solution uses serverless and managed services:

- **OpenSearch Serverless**: ~$700/month (2 OCUs)
- **Bedrock Knowledge Base**: Pay per API call
- **Bedrock Models**: Pay per token
- **Lambda**: Pay per invocation (free tier available)
- **S3**: Pay per GB stored
- **DynamoDB**: Pay per request (free tier available)

**Estimated monthly cost for light usage**: $700-800

To reduce costs:
- Adjust OpenSearch capacity units in `terraform.tfvars`
- Use Nova Lite instead of Nova Pro for generation
- Delete the stack when not in use

## Cleanup

To destroy all resources:

```bash
cd terraform/environments/dev
terraform destroy
```

**Warning**: This will delete all data including documents and store metadata.

## Troubleshooting

### Search Returns No Results

1. Verify documents were uploaded to S3
2. Check ingestion job completed successfully
3. Ensure `.metadata.json` files exist alongside documents
4. Verify `store_id` matches between upload and search

### Ingestion Job Fails

1. Check S3 bucket permissions
2. Verify Bedrock Knowledge Base has access to S3
3. Check CloudWatch Logs for detailed errors
4. Ensure file formats are supported

### Generated Response Empty

1. Verify Nova Pro model is available in your region
2. Check IAM permissions include `bedrock:InvokeModel`
3. Ensure documents contain relevant content
4. Try a more specific query

## Security Considerations

### Current Implementation

- **Authentication**: Trusts provided credentials (demo purposes)
- **Authorization**: Metadata-based filtering only
- **Credentials**: Stored in `.env` file (not for production)

### Production Recommendations

1. **Use Amazon Cognito** for user authentication
2. **Implement API Gateway authorizers** for API access control
3. **Use IAM roles** instead of access keys
4. **Enable CloudTrail** for audit logging
5. **Restrict S3 bucket policies** to specific principals
6. **Enable encryption at rest** for all data stores
7. **Use VPC endpoints** for private connectivity

## Extending the Solution

### Add More Stores

Simply create new stores through the UI - no infrastructure changes needed.

### Support More File Types

Update `allowed_file_types` in `terraform.tfvars`:

```hcl
allowed_file_types = [".pdf", ".docx", ".txt", ".md", ".csv", ".json"]
```

### Use Different Models

Change the generation model in `.env`:

```env
# Faster, lower cost
VITE_GENERATION_MODEL_ID=us.amazon.nova-lite-v1:0

# Claude models
VITE_GENERATION_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0
```

### Add More Environments

Copy `terraform/environments/dev` to `staging` or `prod` and adjust variables.

## Learn More

- [Amazon Bedrock Knowledge Base Documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base.html)
- [Amazon Bedrock Models](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)
- [OpenSearch Serverless](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/serverless.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review AWS CloudWatch Logs
3. Consult AWS Bedrock documentation

---

**Built with ❤️ to demonstrate Amazon Bedrock Knowledge Base capabilities**
