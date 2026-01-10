import {
  StartIngestionJobCommand,
  GetIngestionJobCommand,
  StartIngestionJobCommandOutput,
  GetIngestionJobCommandOutput
} from '@aws-sdk/client-bedrock-agent';
import { BedrockAgentClient } from '@aws-sdk/client-bedrock-agent';
import { awsConfig } from '../config/aws';
import { IngestionJob } from '../types';
import { v4 as uuidv4 } from 'uuid';

export class IngestionService {
  private bedrockAgentClient: BedrockAgentClient;

  constructor() {
    if (!awsConfig.credentials.accessKeyId || !awsConfig.credentials.secretAccessKey) {
      throw new Error('AWS credentials are required. Please set VITE_AWS_ACCESS_KEY_ID and VITE_AWS_SECRET_ACCESS_KEY in your .env file.');
    }

    this.bedrockAgentClient = new BedrockAgentClient({
      region: awsConfig.region,
      credentials: {
        accessKeyId: awsConfig.credentials.accessKeyId,
        secretAccessKey: awsConfig.credentials.secretAccessKey
      }
    });
  }

  async startIngestionJob(): Promise<string> {
    try {
      // Generate a client token that meets the minimum length requirement (33 characters)
      // Using UUID v4 which is 36 characters including hyphens
      const clientToken = uuidv4();
      
      const command = new StartIngestionJobCommand({
        knowledgeBaseId: awsConfig.knowledgeBaseId,
        dataSourceId: awsConfig.dataSourceId,
        clientToken
      });

      const response: StartIngestionJobCommandOutput = await this.bedrockAgentClient.send(command);
      
      if (!response.ingestionJob?.ingestionJobId) {
        throw new Error('Failed to start ingestion job: No job ID returned');
      }

      return response.ingestionJob.ingestionJobId;
    } catch (error) {
      console.error('Start ingestion error:', error);
      throw new Error(`Failed to start ingestion: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  async getIngestionJobStatus(ingestionJobId: string): Promise<IngestionJob> {
    try {
      const command = new GetIngestionJobCommand({
        knowledgeBaseId: awsConfig.knowledgeBaseId,
        dataSourceId: awsConfig.dataSourceId,
        ingestionJobId
      });

      const response: GetIngestionJobCommandOutput = await this.bedrockAgentClient.send(command);
      
      if (!response.ingestionJob) {
        throw new Error('Failed to get ingestion job status');
      }

      return {
        ingestionJobId: response.ingestionJob.ingestionJobId || '',
        status: response.ingestionJob.status as IngestionJob['status'],
        startedAt: response.ingestionJob.startedAt,
        updatedAt: response.ingestionJob.updatedAt,
        statistics: response.ingestionJob.statistics,
        failureReasons: response.ingestionJob.failureReasons
      };
    } catch (error) {
      console.error('Get ingestion status error:', error);
      throw new Error(`Failed to get ingestion status: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  async pollIngestionJob(
    ingestionJobId: string,
    onStatusUpdate: (job: IngestionJob) => void,
    pollIntervalMs: number = 5000,
    maxAttempts: number = 60
  ): Promise<IngestionJob> {
    let attempts = 0;

    while (attempts < maxAttempts) {
      const job = await this.getIngestionJobStatus(ingestionJobId);
      onStatusUpdate(job);

      if (job.status === 'COMPLETE' || job.status === 'FAILED') {
        return job;
      }

      await new Promise(resolve => setTimeout(resolve, pollIntervalMs));
      attempts++;
    }

    throw new Error('Ingestion job polling timeout');
  }
}
