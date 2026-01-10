import { S3Client } from '@aws-sdk/client-s3';
import { BedrockAgentRuntimeClient } from '@aws-sdk/client-bedrock-agent-runtime';
import { awsConfig } from '../config/aws';

// Create S3 client for direct uploads
export const createS3Client = (): S3Client => {
  // For browser-based applications, credentials must be provided explicitly
  // or through Cognito Identity Pool
  if (!awsConfig.credentials.accessKeyId || !awsConfig.credentials.secretAccessKey) {
    throw new Error('AWS credentials are required. Please set VITE_AWS_ACCESS_KEY_ID and VITE_AWS_SECRET_ACCESS_KEY in your .env file.');
  }

  return new S3Client({
    region: awsConfig.region,
    credentials: {
      accessKeyId: awsConfig.credentials.accessKeyId,
      secretAccessKey: awsConfig.credentials.secretAccessKey
    }
  });
};

// Create Bedrock Agent Runtime client for ingestion and search
export const createBedrockAgentClient = (): BedrockAgentRuntimeClient => {
  // For browser-based applications, credentials must be provided explicitly
  // or through Cognito Identity Pool
  if (!awsConfig.credentials.accessKeyId || !awsConfig.credentials.secretAccessKey) {
    throw new Error('AWS credentials are required. Please set VITE_AWS_ACCESS_KEY_ID and VITE_AWS_SECRET_ACCESS_KEY in your .env file.');
  }

  return new BedrockAgentRuntimeClient({
    region: awsConfig.region,
    credentials: {
      accessKeyId: awsConfig.credentials.accessKeyId,
      secretAccessKey: awsConfig.credentials.secretAccessKey
    }
  });
};
