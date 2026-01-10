# Bedrock File Search WebUI

React-based web application for the Bedrock Knowledge Base demo.

## Features

- Store management (create, view, delete stores)
- Direct S3 file uploads with drag-and-drop
- Document ingestion via Bedrock Knowledge Base API
- Semantic search with AI-powered Q&A
- Real-time ingestion status tracking
- Tabbed results view (raw retrieval + generated response)

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

Auto-configure from Terraform outputs:

```bash
(cd ../terraform/environments/dev && terraform refresh && \
 echo "VITE_AWS_REGION=$(terraform output -raw aws_region)" > ../../webui/.env && \
 echo "VITE_KNOWLEDGE_BASE_ID=$(terraform output -raw knowledge_base_id)" >> ../../webui/.env && \
 echo "VITE_DATA_SOURCE_ID=$(terraform output -raw data_source_id)" >> ../../webui/.env && \
 echo "VITE_DATA_SOURCE_BUCKET_NAME=$(terraform output -raw data_source_bucket_name)" >> ../../webui/.env && \
 echo "VITE_API_GATEWAY_ENDPOINT=$(terraform output -raw api_gateway_endpoint)" >> ../../webui/.env && \
 echo "VITE_GENERATION_MODEL_ID=us.amazon.nova-pro-v1:0" >> ../../webui/.env)
```

Add your AWS credentials:

```bash
echo "VITE_AWS_ACCESS_KEY_ID=your_access_key" >> .env
echo "VITE_AWS_SECRET_ACCESS_KEY=your_secret_key" >> .env
```

### 3. Run Development Server

```bash
npm run dev
```

Visit http://localhost:5173

### 4. Build for Production

```bash
npm run build
```

## Environment Variables

Required variables in `.env`:

```env
VITE_AWS_REGION=us-east-1
VITE_KNOWLEDGE_BASE_ID=<from terraform>
VITE_DATA_SOURCE_ID=<from terraform>
VITE_DATA_SOURCE_BUCKET_NAME=<from terraform>
VITE_API_GATEWAY_ENDPOINT=<from terraform>
VITE_GENERATION_MODEL_ID=us.amazon.nova-pro-v1:0
VITE_AWS_ACCESS_KEY_ID=<your credentials>
VITE_AWS_SECRET_ACCESS_KEY=<your credentials>
```

### Available Generation Models

- `us.amazon.nova-pro-v1:0` (Default - balanced performance)
- `us.amazon.nova-lite-v1:0` (Faster, lower cost)
- `anthropic.claude-3-sonnet-20240229-v1:0` (Claude 3 Sonnet)
- `anthropic.claude-3-haiku-20240307-v1:0` (Claude 3 Haiku - fastest)

## Architecture

- **React 18** with TypeScript
- **Vite** for fast development and building
- **React Router** for client-side routing
- **AWS SDK v3** for direct S3 and Bedrock calls
- No backend proxy - all AWS calls made directly from browser

## Pages

- **Stores** (`/`) - Store selection and management
- **Upload** (`/upload`) - File upload with S3 direct upload
- **Search** (`/search`) - Semantic search with AI Q&A

## How It Works

### Document Upload

1. User selects files
2. Files uploaded directly to S3 with metadata
3. `.metadata.json` file created for each document
4. User triggers ingestion job
5. Knowledge Base processes and indexes documents

### Search

1. User enters query
2. Two API calls run in parallel:
   - **Retrieve**: Gets relevant document chunks
   - **RetrieveAndGenerate**: Gets AI-generated answer
3. Results displayed in tabs:
   - Retrieved Documents (raw results with scores)
   - Generated Response (AI answer with citations)

## Development

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Type check
npm run type-check
```

See the main [README.md](../README.md) for complete documentation.
