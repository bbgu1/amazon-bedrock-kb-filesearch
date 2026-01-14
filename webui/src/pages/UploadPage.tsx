import React, { useState, useRef } from 'react';
import { useStore } from '../context/StoreContext';
import { UploadService, UploadProgress } from '../services/uploadService';
import { IngestionService } from '../services/ingestionService';
import { IngestionJob } from '../types';
import { ErrorMessage } from '../components/ErrorMessage';
import { LoadingSpinner } from '../components/LoadingSpinner';
import { validateFileType, SUPPORTED_FILE_TYPES, formatFileSize } from '../utils/validation';

export const UploadPage: React.FC = () => {
  const { selectedStoreId } = useStore();
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<Map<string, UploadProgress>>(new Map());
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [dragActive, setDragActive] = useState(false);
  const [ingesting, setIngesting] = useState(false);
  const [ingestionJob, setIngestionJob] = useState<IngestionJob | null>(null);
  const [showIngestionTrigger, setShowIngestionTrigger] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const uploadService = new UploadService();
  const ingestionService = new IngestionService();

  const handleDrag = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setDragActive(true);
    } else if (e.type === 'dragleave') {
      setDragActive(false);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
    
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      handleFiles(Array.from(e.dataTransfer.files));
    }
  };

  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      handleFiles(Array.from(e.target.files));
    }
  };

  const handleFiles = (files: File[]) => {
    setError(null);
    setSuccess(null);

    // Validate file types
    const invalidFiles = files.filter(file => !validateFileType(file.name));
    if (invalidFiles.length > 0) {
      setError(`Invalid file types: ${invalidFiles.map(f => f.name).join(', ')}. Supported types: ${SUPPORTED_FILE_TYPES.join(', ')}`);
      return;
    }

    setSelectedFiles(prev => [...prev, ...files]);
  };

  const removeFile = (index: number) => {
    setSelectedFiles(prev => prev.filter((_, i) => i !== index));
  };

  const handleUpload = async () => {
    if (!selectedStoreId) {
      setError('Please select a store first');
      return;
    }

    if (selectedFiles.length === 0) {
      setError('Please select files to upload');
      return;
    }

    setError(null);
    setSuccess(null);
    setUploading(true);
    setUploadProgress(new Map());

    try {
      await uploadService.uploadMultipleFiles(
        selectedFiles,
        selectedStoreId,
        (progress) => {
          setUploadProgress(new Map(progress));
        }
      );

      setSuccess(`Successfully uploaded ${selectedFiles.length} file(s) to store ${selectedStoreId}`);
      setSelectedFiles([]);
      setUploadProgress(new Map());
      setShowIngestionTrigger(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Upload failed');
    } finally {
      setUploading(false);
    }
  };

  const handleStartIngestion = async () => {
    setError(null);
    setIngesting(true);
    setIngestionJob(null);

    try {
      const jobId = await ingestionService.startIngestionJob();
      
      // Poll for status updates
      await ingestionService.pollIngestionJob(
        jobId,
        (job) => {
          setIngestionJob(job);
        },
        5000,
        60
      );

      setSuccess('Ingestion completed successfully!');
      setShowIngestionTrigger(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ingestion failed');
    } finally {
      setIngesting(false);
    }
  };

  if (!selectedStoreId) {
    return (
      <div>
        <h2>Upload Documents</h2>
        <div style={{
          backgroundColor: '#fff3cd',
          border: '1px solid #ffc107',
          borderRadius: '4px',
          padding: '1rem',
          color: '#856404'
        }}>
          Please select a store from the Stores page before uploading documents.
        </div>
      </div>
    );
  }

  return (
    <div>
      <h2>Upload Documents</h2>
      
      <div style={{
        backgroundColor: '#f5f5f5',
        padding: '1rem',
        borderRadius: '4px',
        marginBottom: '1.5rem'
      }}>
        <strong>Current Store:</strong> {selectedStoreId}
      </div>

      {error && <ErrorMessage message={error} onDismiss={() => setError(null)} />}
      
      {success && (
        <div style={{
          backgroundColor: '#d4edda',
          border: '1px solid #c3e6cb',
          borderRadius: '4px',
          padding: '1rem',
          marginBottom: '1rem',
          color: '#155724'
        }}>
          {success}
        </div>
      )}

      {/* Drag and Drop Area */}
      <div
        onDragEnter={handleDrag}
        onDragLeave={handleDrag}
        onDragOver={handleDrag}
        onDrop={handleDrop}
        onClick={() => fileInputRef.current?.click()}
        style={{
          border: `2px dashed ${dragActive ? '#ff9900' : '#ddd'}`,
          borderRadius: '8px',
          padding: '3rem',
          textAlign: 'center',
          cursor: 'pointer',
          backgroundColor: dragActive ? '#fff8f0' : 'white',
          marginBottom: '1.5rem',
          transition: 'all 0.3s ease'
        }}
      >
        <input
          ref={fileInputRef}
          type="file"
          multiple
          onChange={handleFileInput}
          style={{ display: 'none' }}
          accept={SUPPORTED_FILE_TYPES.join(',')}
        />
        <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>📁</div>
        <p style={{ fontSize: '1.2rem', marginBottom: '0.5rem' }}>
          {dragActive ? 'Drop files here' : 'Drag and drop files here'}
        </p>
        <p style={{ color: '#666' }}>or click to browse</p>
        <p style={{ fontSize: '0.9rem', color: '#999', marginTop: '1rem' }}>
          Supported formats: {SUPPORTED_FILE_TYPES.join(', ')}
        </p>
      </div>

      {/* Selected Files List */}
      {selectedFiles.length > 0 && (
        <div style={{
          border: '1px solid #ddd',
          borderRadius: '8px',
          padding: '1.5rem',
          marginBottom: '1.5rem'
        }}>
          <h3 style={{ marginTop: 0 }}>Selected Files ({selectedFiles.length})</h3>
          <div style={{ maxHeight: '300px', overflowY: 'auto' }}>
            {selectedFiles.map((file, index) => (
              <div
                key={index}
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  padding: '0.75rem',
                  backgroundColor: index % 2 === 0 ? '#f9f9f9' : 'white',
                  borderRadius: '4px',
                  marginBottom: '0.5rem'
                }}
              >
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 'bold' }}>{file.name}</div>
                  <div style={{ fontSize: '0.9rem', color: '#666' }}>
                    {formatFileSize(file.size)} • {file.type || 'Unknown type'}
                  </div>
                </div>
                {!uploading && (
                  <button
                    onClick={() => removeFile(index)}
                    style={{
                      padding: '0.25rem 0.75rem',
                      backgroundColor: '#dc3545',
                      color: 'white',
                      border: 'none',
                      borderRadius: '4px',
                      cursor: 'pointer',
                      fontSize: '0.9rem'
                    }}
                  >
                    Remove
                  </button>
                )}
              </div>
            ))}
          </div>

          <button
            onClick={handleUpload}
            disabled={uploading}
            style={{
              marginTop: '1rem',
              padding: '0.75rem 2rem',
              backgroundColor: uploading ? '#ccc' : '#ff9900',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: uploading ? 'not-allowed' : 'pointer',
              fontSize: '1rem',
              fontWeight: 'bold'
            }}
          >
            {uploading ? 'Uploading...' : `Upload ${selectedFiles.length} File(s)`}
          </button>
        </div>
      )}

      {/* Upload Progress */}
      {uploadProgress.size > 0 && (
        <div style={{
          border: '1px solid #ddd',
          borderRadius: '8px',
          padding: '1.5rem'
        }}>
          <h3 style={{ marginTop: 0 }}>Upload Progress</h3>
          {Array.from(uploadProgress.values()).map((progress, index) => (
            <div key={index} style={{ marginBottom: '1rem' }}>
              <div style={{
                display: 'flex',
                justifyContent: 'space-between',
                marginBottom: '0.25rem'
              }}>
                <span>{progress.filename}</span>
                <span style={{
                  color: progress.status === 'complete' ? '#28a745' :
                         progress.status === 'error' ? '#dc3545' :
                         '#666'
                }}>
                  {progress.status === 'complete' ? '✓ Complete' :
                   progress.status === 'error' ? '✗ Error' :
                   progress.status === 'uploading' ? `${progress.progress}%` :
                   'Pending'}
                </span>
              </div>
              <div style={{
                width: '100%',
                height: '8px',
                backgroundColor: '#e0e0e0',
                borderRadius: '4px',
                overflow: 'hidden'
              }}>
                <div style={{
                  width: `${progress.progress}%`,
                  height: '100%',
                  backgroundColor: progress.status === 'error' ? '#dc3545' :
                                 progress.status === 'complete' ? '#28a745' :
                                 '#ff9900',
                  transition: 'width 0.3s ease'
                }} />
              </div>
              {progress.error && (
                <div style={{ color: '#dc3545', fontSize: '0.9rem', marginTop: '0.25rem' }}>
                  {progress.error}
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Ingestion Trigger */}
      {showIngestionTrigger && !ingesting && !ingestionJob && (
        <div style={{
          border: '2px solid #ff9900',
          borderRadius: '8px',
          padding: '1.5rem',
          marginBottom: '1.5rem',
          backgroundColor: '#fff8f0'
        }}>
          <h3 style={{ marginTop: 0, color: '#ff9900' }}>Ready to Ingest Documents</h3>
          <p>
            Your files have been uploaded to S3. Click the button below to start the ingestion process
            and make them searchable in the Knowledge Base.
          </p>
          <button
            onClick={handleStartIngestion}
            style={{
              padding: '0.75rem 2rem',
              backgroundColor: '#ff9900',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer',
              fontSize: '1rem',
              fontWeight: 'bold'
            }}
          >
            Start Ingestion
          </button>
        </div>
      )}

      {/* Ingestion Progress */}
      {ingesting && (
        <div style={{
          border: '1px solid #ddd',
          borderRadius: '8px',
          padding: '1.5rem',
          marginBottom: '1.5rem'
        }}>
          <h3 style={{ marginTop: 0 }}>Ingestion in Progress</h3>
          {!ingestionJob && <LoadingSpinner message="Starting ingestion job..." />}
          
          {ingestionJob && (
            <div>
              <div style={{
                display: 'grid',
                gridTemplateColumns: '150px 1fr',
                gap: '0.5rem',
                marginBottom: '1rem'
              }}>
                <strong>Job ID:</strong>
                <span style={{ fontFamily: 'monospace', fontSize: '0.9rem' }}>
                  {ingestionJob.ingestionJobId}
                </span>
                
                <strong>Status:</strong>
                <span style={{
                  fontWeight: 'bold',
                  color: ingestionJob.status === 'COMPLETE' ? '#28a745' :
                         ingestionJob.status === 'FAILED' ? '#dc3545' :
                         '#ff9900'
                }}>
                  {ingestionJob.status}
                </span>

                {ingestionJob.statistics && (
                  <>
                    <strong>Scanned:</strong>
                    <span>{ingestionJob.statistics.numberOfDocumentsScanned || 0}</span>
                    
                    <strong>Indexed:</strong>
                    <span>{ingestionJob.statistics.numberOfDocumentsIndexed || 0}</span>
                    
                    {ingestionJob.statistics.numberOfDocumentsFailed ? (
                      <>
                        <strong>Failed:</strong>
                        <span style={{ color: '#dc3545' }}>
                          {ingestionJob.statistics.numberOfDocumentsFailed}
                        </span>
                      </>
                    ) : null}
                  </>
                )}
              </div>

              {ingestionJob.status === 'IN_PROGRESS' && (
                <LoadingSpinner message="Processing documents..." />
              )}

              {ingestionJob.failureReasons && ingestionJob.failureReasons.length > 0 && (
                <div style={{
                  backgroundColor: '#fee',
                  border: '1px solid #fcc',
                  borderRadius: '4px',
                  padding: '1rem',
                  marginTop: '1rem'
                }}>
                  <strong style={{ color: '#c00' }}>Failure Reasons:</strong>
                  <ul style={{ marginBottom: 0, paddingLeft: '1.5rem' }}>
                    {ingestionJob.failureReasons.map((reason, index) => (
                      <li key={index} style={{ color: '#c00' }}>{reason}</li>
                    ))}
                  </ul>
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
        marginTop: '1.5rem'
      }}>
        <h4 style={{ marginTop: 0, color: '#004085' }}>Upload Information</h4>
        <ul style={{ marginBottom: 0, paddingLeft: '1.5rem', color: '#004085' }}>
          <li>Files are uploaded directly to S3 with the pattern: {`{store_id}/{document_id}/{filename}`}</li>
          <li>After uploading, click "Start Ingestion" to process documents into the Knowledge Base</li>
          <li><strong>Note:</strong> Ingestion syncs all new/modified files in the bucket (all stores)</li>
          <li><strong>Search is filtered by store:</strong> You will only see results for your current store</li>
          <li>Ingestion typically takes a few minutes depending on file count and size</li>
          <li>Supported formats: Text (.txt, .md), PDF, Images (.png, .jpg), Office (.docx, .xlsx)</li>
          <li>All files will be associated with the current store: {selectedStoreId}</li>
        </ul>
      </div>
    </div>
  );
};
