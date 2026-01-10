import {
  RetrieveCommand,
  RetrieveCommandOutput,
  RetrieveAndGenerateCommand,
  RetrieveAndGenerateCommandOutput,
  KnowledgeBaseRetrievalResult
} from '@aws-sdk/client-bedrock-agent-runtime';
import { createBedrockAgentClient } from './awsClients';
import { awsConfig } from '../config/aws';
import { SearchResult, GeneratedResponse } from '../types';

export class SearchService {
  private bedrockAgentClient = createBedrockAgentClient();

  async search(query: string, storeId: string, maxResults: number = 10): Promise<SearchResult[]> {
    try {
      // Use Bedrock's native metadata filtering
      // Filter by the store_id field from the .metadata.json file
      const command = new RetrieveCommand({
        knowledgeBaseId: awsConfig.knowledgeBaseId,
        retrievalQuery: {
          text: query
        },
        retrievalConfiguration: {
          vectorSearchConfiguration: {
            numberOfResults: maxResults,
            filter: {
              // Filter by store_id metadata from .metadata.json file
              // Bedrock reads metadata from <filename>.metadata.json
              equals: {
                key: 'store_id',
                value: storeId
              }
            }
          }
        }
      });

      const response: RetrieveCommandOutput = await this.bedrockAgentClient.send(command);

      if (!response.retrievalResults) {
        return [];
      }

      // Log metadata from first result to debug
      if (response.retrievalResults.length > 0) {
        const firstResult = response.retrievalResults[0];
        console.log('Sample metadata keys:', Object.keys(firstResult.metadata || {}));
        console.log('Sample metadata:', firstResult.metadata);
        console.log('Sample S3 location:', firstResult.metadata?.['x-amz-bedrock-kb-source-uri']);
      }

      // Take only the requested number of results
      const filteredResults = response.retrievalResults.slice(0, maxResults);

      return filteredResults.map((result: KnowledgeBaseRetrievalResult) => {
        const metadata = result.metadata || {};
        
        // Helper to safely get string value from metadata
        const getMetadataString = (key: string, defaultValue: string = 'unknown'): string => {
          const value = metadata[key];
          if (typeof value === 'string') return value;
          if (typeof value === 'number') return value.toString();
          return defaultValue;
        };
        
        // Extract store_id from metadata or S3 location as fallback
        const s3Location = getMetadataString('x-amz-bedrock-kb-source-uri');
        const pathMatch = s3Location.match(/s3:\/\/[^\/]+\/([^\/]+)\//);
        const extractedStoreId = getMetadataString('store_id') || (pathMatch ? pathMatch[1] : storeId);
        
        return {
          content: result.content?.text || '',
          score: result.score || 0,
          metadata: {
            document_id: getMetadataString('document_id') || getMetadataString('x-amz-bedrock-kb-document-id'),
            store_id: extractedStoreId,
            filename: getMetadataString('filename') || s3Location.split('/').pop()?.replace('.metadata.json', '') || 'unknown',
            content_type: getMetadataString('content_type'),
            upload_date: getMetadataString('upload_date', new Date().toISOString()),
            s3_location: s3Location,
            file_size: parseInt(getMetadataString('file_size', '0'), 10)
          }
        };
      });
    } catch (error) {
      console.error('Search error:', error);
      throw new Error(`Search failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  async retrieveAndGenerate(query: string, storeId: string): Promise<GeneratedResponse> {
    try {
      const command = new RetrieveAndGenerateCommand({
        input: {
          text: query
        },
        retrieveAndGenerateConfiguration: {
          type: 'KNOWLEDGE_BASE',
          knowledgeBaseConfiguration: {
            knowledgeBaseId: awsConfig.knowledgeBaseId,
            modelArn: `${awsConfig.generationModelId}`,
            retrievalConfiguration: {
              vectorSearchConfiguration: {
                numberOfResults: 5,
                filter: {
                  equals: {
                    key: 'store_id',
                    value: storeId
                  }
                }
              }
            }
          }
        }
      });

      const response: RetrieveAndGenerateCommandOutput = await this.bedrockAgentClient.send(command);

      if (!response.output?.text) {
        throw new Error('No generated response received');
      }

      // Extract citations from the response
      const citations = response.citations?.map(citation => ({
        text: citation.generatedResponsePart?.textResponsePart?.text || '',
        references: citation.retrievedReferences?.map(ref => ({
          content: ref.content?.text || '',
          location: ref.location?.s3Location?.uri || '',
          metadata: ref.metadata || {}
        })) || []
      })) || [];

      return {
        generatedText: response.output.text,
        citations,
        sessionId: response.sessionId
      };
    } catch (error) {
      console.error('Retrieve and generate error:', error);
      throw new Error(`Retrieve and generate failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }
}
