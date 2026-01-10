// Store types
export interface Store {
  store_id: string;
  name: string;
  description?: string;
  created_at: string;
  updated_at: string;
  metadata?: Record<string, any>;
}

export interface CreateStoreRequest {
  store_id: string;
  name: string;
  description?: string;
  metadata?: Record<string, any>;
}

// Document types
export interface DocumentMetadata {
  document_id: string;
  store_id: string;
  filename: string;
  content_type: string;
  upload_date: string;
  s3_location: string;
  file_size: number;
}

// Search types
export interface SearchResult {
  content: string;
  score: number;
  metadata: DocumentMetadata;
}

export interface CitationReference {
  content: string;
  location: string;
  metadata: Record<string, any>;
}

export interface Citation {
  text: string;
  references: CitationReference[];
}

export interface GeneratedResponse {
  generatedText: string;
  citations: Citation[];
  sessionId?: string;
}

// Ingestion types
export interface IngestionJob {
  ingestionJobId: string;
  status: 'STARTING' | 'IN_PROGRESS' | 'COMPLETE' | 'FAILED';
  startedAt?: Date;
  updatedAt?: Date;
  statistics?: {
    numberOfDocumentsScanned?: number;
    numberOfDocumentsIndexed?: number;
    numberOfDocumentsFailed?: number;
  };
  failureReasons?: string[];
}

// Error types
export interface ApiError {
  error: {
    code: string;
    message: string;
    details?: Record<string, any>;
  };
}
