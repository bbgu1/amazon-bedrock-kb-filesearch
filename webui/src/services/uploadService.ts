import { PutObjectCommand } from '@aws-sdk/client-s3';
import { createS3Client } from './awsClients';
import { awsConfig } from '../config/aws';
import { v4 as uuidv4 } from 'uuid';

export interface UploadProgress {
  filename: string;
  progress: number;
  status: 'pending' | 'uploading' | 'complete' | 'error';
  error?: string;
}

export class UploadService {
  private s3Client = createS3Client();

  async uploadFile(
    file: File,
    storeId: string,
    onProgress?: (progress: number) => void
  ): Promise<string> {
    const documentId = uuidv4();
    const key = `${storeId}/${documentId}/${file.name}`;
    const metadataKey = `${key}.metadata.json`;

    try {
      // Convert File to Uint8Array for browser compatibility
      const arrayBuffer = await file.arrayBuffer();
      const uint8Array = new Uint8Array(arrayBuffer);
      
      // Upload the document file
      const uploadCommand = new PutObjectCommand({
        Bucket: awsConfig.dataSourceBucketName,
        Key: key,
        Body: uint8Array,
        ContentType: file.type,
        Metadata: {
          'store-id': storeId,
          'document-id': documentId,
          'original-filename': file.name
        }
      });

      await this.s3Client.send(uploadCommand);
      
      // Create and upload the metadata file for Bedrock Knowledge Base
      // Bedrock reads metadata from <filename>.metadata.json
      const metadata = {
        metadataAttributes: {
          store_id: storeId,
          document_id: documentId,
          filename: file.name,
          content_type: file.type,
          upload_date: new Date().toISOString(),
          file_size: file.size
        }
      };

      const metadataCommand = new PutObjectCommand({
        Bucket: awsConfig.dataSourceBucketName,
        Key: metadataKey,
        Body: JSON.stringify(metadata),
        ContentType: 'application/json'
      });

      await this.s3Client.send(metadataCommand);
      
      if (onProgress) {
        onProgress(100);
      }

      return key;
    } catch (error) {
      console.error('Upload error:', error);
      throw new Error(`Failed to upload ${file.name}: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  async uploadMultipleFiles(
    files: File[],
    storeId: string,
    onProgressUpdate?: (fileProgress: Map<string, UploadProgress>) => void
  ): Promise<string[]> {
    const progressMap = new Map<string, UploadProgress>();
    
    // Initialize progress for all files
    files.forEach(file => {
      progressMap.set(file.name, {
        filename: file.name,
        progress: 0,
        status: 'pending'
      });
    });

    if (onProgressUpdate) {
      onProgressUpdate(new Map(progressMap));
    }

    const uploadPromises = files.map(async (file) => {
      try {
        progressMap.set(file.name, {
          filename: file.name,
          progress: 0,
          status: 'uploading'
        });
        
        if (onProgressUpdate) {
          onProgressUpdate(new Map(progressMap));
        }

        const key = await this.uploadFile(file, storeId, (progress) => {
          progressMap.set(file.name, {
            filename: file.name,
            progress,
            status: 'uploading'
          });
          
          if (onProgressUpdate) {
            onProgressUpdate(new Map(progressMap));
          }
        });

        progressMap.set(file.name, {
          filename: file.name,
          progress: 100,
          status: 'complete'
        });
        
        if (onProgressUpdate) {
          onProgressUpdate(new Map(progressMap));
        }

        return key;
      } catch (error) {
        progressMap.set(file.name, {
          filename: file.name,
          progress: 0,
          status: 'error',
          error: error instanceof Error ? error.message : 'Upload failed'
        });
        
        if (onProgressUpdate) {
          onProgressUpdate(new Map(progressMap));
        }

        throw error;
      }
    });

    return Promise.all(uploadPromises);
  }
}
