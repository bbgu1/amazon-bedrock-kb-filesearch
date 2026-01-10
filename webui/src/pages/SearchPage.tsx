import React, { useState } from 'react';
import { useStore } from '../context/StoreContext';
import { SearchService } from '../services/searchService';
import { SearchResult, GeneratedResponse } from '../types';
import { ErrorMessage } from '../components/ErrorMessage';
import { LoadingSpinner } from '../components/LoadingSpinner';

type TabType = 'retrieval' | 'generated';

export const SearchPage: React.FC = () => {
  const { selectedStoreId } = useStore();
  const [query, setQuery] = useState('');
  const [searching, setSearching] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [results, setResults] = useState<SearchResult[]>([]);
  const [generatedResponse, setGeneratedResponse] = useState<GeneratedResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [hasSearched, setHasSearched] = useState(false);
  const [activeTab, setActiveTab] = useState<TabType>('retrieval');
  const searchService = new SearchService();

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!selectedStoreId) {
      setError('Please select a store first');
      return;
    }

    if (!query.trim()) {
      setError('Please enter a search query');
      return;
    }

    setError(null);
    setSearching(true);
    setGenerating(true);
    setHasSearched(true);

    try {
      // Run both retrieval and generation in parallel
      const [searchResults, generatedResp] = await Promise.all([
        searchService.search(query, selectedStoreId),
        searchService.retrieveAndGenerate(query, selectedStoreId)
      ]);
      
      setResults(searchResults);
      setGeneratedResponse(generatedResp);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Search failed');
      setResults([]);
      setGeneratedResponse(null);
    } finally {
      setSearching(false);
      setGenerating(false);
    }
  };

  const highlightText = (text: string, query: string): React.ReactNode => {
    if (!query.trim()) return text;

    const parts = text.split(new RegExp(`(${query})`, 'gi'));
    return parts.map((part, index) =>
      part.toLowerCase() === query.toLowerCase() ? (
        <mark key={index} style={{ backgroundColor: '#ffeb3b', padding: '0 2px' }}>
          {part}
        </mark>
      ) : (
        part
      )
    );
  };

  if (!selectedStoreId) {
    return (
      <div>
        <h2>Search Documents</h2>
        <div style={{
          backgroundColor: '#fff3cd',
          border: '1px solid #ffc107',
          borderRadius: '4px',
          padding: '1rem',
          color: '#856404'
        }}>
          Please select a store from the Stores page before searching documents.
        </div>
      </div>
    );
  }

  return (
    <div>
      <h2>Search Documents</h2>

      <div style={{
        backgroundColor: '#f5f5f5',
        padding: '1rem',
        borderRadius: '4px',
        marginBottom: '1.5rem'
      }}>
        <strong>Current Store:</strong> {selectedStoreId}
      </div>

      {error && <ErrorMessage message={error} onDismiss={() => setError(null)} />}

      {/* Search Form */}
      <form onSubmit={handleSearch} style={{ marginBottom: '2rem' }}>
        <div style={{
          display: 'flex',
          gap: '1rem',
          alignItems: 'stretch'
        }}>
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Enter your search query..."
            disabled={searching}
            style={{
              flex: 1,
              padding: '0.75rem',
              border: '1px solid #ddd',
              borderRadius: '4px',
              fontSize: '1rem'
            }}
          />
          <button
            type="submit"
            disabled={searching || !query.trim()}
            style={{
              padding: '0.75rem 2rem',
              backgroundColor: searching || !query.trim() ? '#ccc' : '#ff9900',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: searching || !query.trim() ? 'not-allowed' : 'pointer',
              fontSize: '1rem',
              fontWeight: 'bold'
            }}
          >
            {searching ? 'Searching...' : 'Search'}
          </button>
        </div>
      </form>

      {/* Loading State */}
      {(searching || generating) && <LoadingSpinner message="Searching documents and generating response..." />}

      {/* Tabs and Results */}
      {!searching && !generating && hasSearched && (
        <div>
          {/* Tab Navigation */}
          <div style={{
            display: 'flex',
            borderBottom: '2px solid #ddd',
            marginBottom: '1.5rem'
          }}>
            <button
              onClick={() => setActiveTab('retrieval')}
              style={{
                padding: '1rem 2rem',
                backgroundColor: activeTab === 'retrieval' ? 'white' : '#f5f5f5',
                border: 'none',
                borderBottom: activeTab === 'retrieval' ? '3px solid #ff9900' : '3px solid transparent',
                cursor: 'pointer',
                fontSize: '1rem',
                fontWeight: activeTab === 'retrieval' ? 'bold' : 'normal',
                color: activeTab === 'retrieval' ? '#232f3e' : '#666',
                transition: 'all 0.2s'
              }}
            >
              📄 Retrieved Documents ({results.length})
            </button>
            <button
              onClick={() => setActiveTab('generated')}
              style={{
                padding: '1rem 2rem',
                backgroundColor: activeTab === 'generated' ? 'white' : '#f5f5f5',
                border: 'none',
                borderBottom: activeTab === 'generated' ? '3px solid #ff9900' : '3px solid transparent',
                cursor: 'pointer',
                fontSize: '1rem',
                fontWeight: activeTab === 'generated' ? 'bold' : 'normal',
                color: activeTab === 'generated' ? '#232f3e' : '#666',
                transition: 'all 0.2s'
              }}
            >
              ✨ Generated Response
            </button>
          </div>

          {/* Retrieval Tab Content */}
          {activeTab === 'retrieval' && (
            <div>
              <div style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: '1rem'
              }}>
                <h3 style={{ margin: 0 }}>
                  Search Results {results.length > 0 && `(${results.length})`}
                </h3>
                {results.length > 0 && (
                  <span style={{ color: '#666', fontSize: '0.9rem' }}>
                    Showing top {results.length} results
                  </span>
                )}
              </div>

              {results.length === 0 ? (
                <div style={{
                  backgroundColor: '#f5f5f5',
                  border: '1px solid #ddd',
                  borderRadius: '8px',
                  padding: '2rem',
                  textAlign: 'center',
                  color: '#666'
                }}>
                  <p style={{ fontSize: '1.2rem', marginBottom: '0.5rem' }}>No results found</p>
                  <p style={{ margin: 0 }}>
                    Try a different search query or make sure documents have been ingested for this store.
                  </p>
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  {results.map((result, index) => (
                    <div
                      key={index}
                      style={{
                        border: '1px solid #ddd',
                        borderRadius: '8px',
                        padding: '1.5rem',
                        backgroundColor: 'white',
                        boxShadow: '0 2px 4px rgba(0,0,0,0.05)'
                      }}
                    >
                      {/* Result Header */}
                      <div style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'flex-start',
                        marginBottom: '1rem'
                      }}>
                        <div style={{ flex: 1 }}>
                          <h4 style={{
                            margin: '0 0 0.5rem 0',
                            color: '#232f3e',
                            fontSize: '1.1rem'
                          }}>
                            {result.metadata.filename}
                          </h4>
                          <div style={{
                            display: 'flex',
                            gap: '1rem',
                            fontSize: '0.85rem',
                            color: '#666'
                          }}>
                            <span>Type: {result.metadata.content_type}</span>
                            {result.metadata.s3_location && (
                              <span title={result.metadata.s3_location}>
                                📍 S3
                              </span>
                            )}
                          </div>
                        </div>
                        <div style={{
                          backgroundColor: '#e7f3ff',
                          color: '#004085',
                          padding: '0.25rem 0.75rem',
                          borderRadius: '12px',
                          fontSize: '0.85rem',
                          fontWeight: 'bold',
                          whiteSpace: 'nowrap'
                        }}>
                          Score: {(result.score * 100).toFixed(1)}%
                        </div>
                      </div>

                      {/* Result Content */}
                      <div style={{
                        backgroundColor: '#f9f9f9',
                        padding: '1rem',
                        borderRadius: '4px',
                        borderLeft: '3px solid #ff9900',
                        fontSize: '0.95rem',
                        lineHeight: '1.6',
                        color: '#333'
                      }}>
                        {highlightText(
                          result.content.length > 500
                            ? result.content.substring(0, 500) + '...'
                            : result.content,
                          query
                        )}
                      </div>

                      {/* Result Metadata */}
                      <div style={{
                        marginTop: '1rem',
                        paddingTop: '1rem',
                        borderTop: '1px solid #eee',
                        display: 'grid',
                        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                        gap: '0.5rem',
                        fontSize: '0.85rem',
                        color: '#666'
                      }}>
                        <div>
                          <strong>Document ID:</strong>{' '}
                          <span style={{ fontFamily: 'monospace', fontSize: '0.8rem' }}>
                            {result.metadata.document_id.substring(0, 12)}...
                          </span>
                        </div>
                        <div>
                          <strong>Store ID:</strong> {result.metadata.store_id}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Generated Response Tab Content */}
          {activeTab === 'generated' && (
            <div>
              <h3 style={{ marginTop: 0, marginBottom: '1rem' }}>AI-Generated Response</h3>
              
              {generatedResponse ? (
                <div>
                  {/* Generated Text */}
                  <div style={{
                    backgroundColor: 'white',
                    border: '1px solid #ddd',
                    borderRadius: '8px',
                    padding: '1.5rem',
                    marginBottom: '1.5rem',
                    boxShadow: '0 2px 4px rgba(0,0,0,0.05)'
                  }}>
                    <div style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem',
                      marginBottom: '1rem',
                      paddingBottom: '1rem',
                      borderBottom: '2px solid #f0f0f0'
                    }}>
                      <span style={{ fontSize: '1.5rem' }}>✨</span>
                      <h4 style={{ margin: 0, color: '#232f3e' }}>Generated Answer</h4>
                    </div>
                    <div style={{
                      fontSize: '1rem',
                      lineHeight: '1.8',
                      color: '#333',
                      whiteSpace: 'pre-wrap'
                    }}>
                      {generatedResponse.generatedText}
                    </div>
                  </div>

                  {/* Citations */}
                  {generatedResponse.citations && generatedResponse.citations.length > 0 && (
                    <div>
                      <h4 style={{ marginBottom: '1rem', color: '#232f3e' }}>
                        📚 Sources ({generatedResponse.citations.length})
                      </h4>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                        {generatedResponse.citations.map((citation, index) => (
                          <div
                            key={index}
                            style={{
                              backgroundColor: '#f9f9f9',
                              border: '1px solid #e0e0e0',
                              borderRadius: '6px',
                              padding: '1rem'
                            }}
                          >
                            {citation.text && (
                              <div style={{
                                fontSize: '0.9rem',
                                color: '#666',
                                marginBottom: '0.75rem',
                                fontStyle: 'italic'
                              }}>
                                "{citation.text}"
                              </div>
                            )}
                            {citation.references && citation.references.length > 0 && (
                              <div style={{ fontSize: '0.85rem' }}>
                                {citation.references.map((ref, refIndex) => (
                                  <div
                                    key={refIndex}
                                    style={{
                                      marginTop: refIndex > 0 ? '0.5rem' : 0,
                                      paddingTop: refIndex > 0 ? '0.5rem' : 0,
                                      borderTop: refIndex > 0 ? '1px solid #e0e0e0' : 'none'
                                    }}
                                  >
                                    <div style={{ color: '#666', marginBottom: '0.25rem' }}>
                                      <strong>Source:</strong> {ref.location || 'Unknown'}
                                    </div>
                                    {ref.content && (
                                      <div style={{
                                        backgroundColor: 'white',
                                        padding: '0.5rem',
                                        borderRadius: '4px',
                                        fontSize: '0.85rem',
                                        color: '#555',
                                        maxHeight: '100px',
                                        overflow: 'auto'
                                      }}>
                                        {ref.content.substring(0, 200)}
                                        {ref.content.length > 200 && '...'}
                                      </div>
                                    )}
                                  </div>
                                ))}
                              </div>
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Model Info */}
                  <div style={{
                    marginTop: '1.5rem',
                    padding: '1rem',
                    backgroundColor: '#e7f3ff',
                    border: '1px solid #b3d9ff',
                    borderRadius: '4px',
                    fontSize: '0.85rem',
                    color: '#004085'
                  }}>
                    <strong>Model:</strong> Amazon Nova Pro • 
                    {generatedResponse.sessionId && (
                      <span> Session ID: {generatedResponse.sessionId.substring(0, 12)}...</span>
                    )}
                  </div>
                </div>
              ) : (
                <div style={{
                  backgroundColor: '#f5f5f5',
                  border: '1px solid #ddd',
                  borderRadius: '8px',
                  padding: '2rem',
                  textAlign: 'center',
                  color: '#666'
                }}>
                  <p style={{ fontSize: '1.2rem', marginBottom: '0.5rem' }}>No response generated</p>
                  <p style={{ margin: 0 }}>
                    The AI was unable to generate a response. Try a different query or check if documents are available.
                  </p>
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* Information Box */}
      <div style={{
        backgroundColor: '#e7f3ff',
        border: '1px solid #b3d9ff',
        borderRadius: '4px',
        padding: '1rem',
        marginTop: '2rem'
      }}>
        <h4 style={{ marginTop: 0, color: '#004085' }}>Search Information</h4>
        <ul style={{ marginBottom: 0, paddingLeft: '1.5rem', color: '#004085' }}>
          <li><strong>Retrieved Documents:</strong> Shows raw semantic search results with relevance scores</li>
          <li><strong>Generated Response:</strong> AI-powered answer synthesized from retrieved documents</li>
          <li>Search uses Amazon Nova multimodal embeddings for semantic similarity</li>
          <li>Results are automatically filtered to the current store: {selectedStoreId}</li>
          <li>Make sure documents have been uploaded and ingested before searching</li>
        </ul>
      </div>
    </div>
  );
};
