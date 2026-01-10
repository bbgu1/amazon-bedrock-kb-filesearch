/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_AWS_REGION: string;
  readonly VITE_KNOWLEDGE_BASE_ID: string;
  readonly VITE_DATA_SOURCE_ID: string;
  readonly VITE_BEDROCK_AGENT_ID: string;
  readonly VITE_BEDROCK_AGENT_ALIAS_ID: string;
  readonly VITE_DATA_SOURCE_BUCKET_NAME: string;
  readonly VITE_API_GATEWAY_ENDPOINT: string;
  readonly VITE_GENERATION_MODEL_ID: string;
  readonly VITE_AWS_ACCESS_KEY_ID?: string;
  readonly VITE_AWS_SECRET_ACCESS_KEY?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
