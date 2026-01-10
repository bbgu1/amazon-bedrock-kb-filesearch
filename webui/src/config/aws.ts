// AWS Configuration
export const awsConfig = {
  region: import.meta.env.VITE_AWS_REGION || 'us-east-1',
  knowledgeBaseId: import.meta.env.VITE_KNOWLEDGE_BASE_ID || '',
  dataSourceId: import.meta.env.VITE_DATA_SOURCE_ID || '',
  dataSourceBucketName: import.meta.env.VITE_DATA_SOURCE_BUCKET_NAME || '',
  apiGatewayEndpoint: import.meta.env.VITE_API_GATEWAY_ENDPOINT || '',
  generationModelId: import.meta.env.VITE_GENERATION_MODEL_ID || 'us.amazon.nova-pro-v1:0',
  credentials: {
    accessKeyId: import.meta.env.VITE_AWS_ACCESS_KEY_ID || '',
    secretAccessKey: import.meta.env.VITE_AWS_SECRET_ACCESS_KEY || ''
  }
};

// Validate required configuration
export const validateConfig = (): string[] => {
  const errors: string[] = [];
  
  if (!awsConfig.region) errors.push('AWS Region is not configured');
  if (!awsConfig.knowledgeBaseId) errors.push('Knowledge Base ID is not configured');
  if (!awsConfig.dataSourceId) errors.push('Data Source ID is not configured');
  if (!awsConfig.dataSourceBucketName) errors.push('Data Source Bucket Name is not configured');
  if (!awsConfig.apiGatewayEndpoint) errors.push('API Gateway Endpoint is not configured');
  
  return errors;
};
