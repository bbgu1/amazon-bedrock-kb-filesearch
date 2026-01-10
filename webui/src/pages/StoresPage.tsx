import React, { useState } from 'react';
import { useStore } from '../context/StoreContext';
import { StoreService } from '../services/storeService';
import { Store, CreateStoreRequest } from '../types';
import { ErrorMessage } from '../components/ErrorMessage';
import { LoadingSpinner } from '../components/LoadingSpinner';
import { validateStoreId } from '../utils/validation';
import { formatDate } from '../utils/validation';

export const StoresPage: React.FC = () => {
  const { selectedStoreId, setSelectedStoreId } = useStore();
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [currentStore, setCurrentStore] = useState<Store | null>(null);
  
  // Create store form state
  const [newStoreId, setNewStoreId] = useState('');
  const [newStoreName, setNewStoreName] = useState('');
  const [newStoreDescription, setNewStoreDescription] = useState('');

  const handleCreateStore = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!validateStoreId(newStoreId)) {
      setError('Store ID must contain only alphanumeric characters, hyphens, and underscores');
      return;
    }

    if (!newStoreName.trim()) {
      setError('Store name is required');
      return;
    }

    setLoading(true);
    try {
      const request: CreateStoreRequest = {
        store_id: newStoreId,
        name: newStoreName,
        description: newStoreDescription || undefined
      };

      const store = await StoreService.createStore(request);
      setSelectedStoreId(store.store_id);
      setCurrentStore(store);
      setShowCreateForm(false);
      setNewStoreId('');
      setNewStoreName('');
      setNewStoreDescription('');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create store');
    } finally {
      setLoading(false);
    }
  };

  const handleLoadStore = async () => {
    if (!selectedStoreId) return;

    setError(null);
    setLoading(true);
    try {
      const store = await StoreService.getStore(selectedStoreId);
      setCurrentStore(store);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load store');
      setCurrentStore(null);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteStore = async () => {
    if (!selectedStoreId) return;
    
    if (!confirm(`Are you sure you want to delete store "${selectedStoreId}"? This action cannot be undone.`)) {
      return;
    }

    setError(null);
    setLoading(true);
    try {
      await StoreService.deleteStore(selectedStoreId);
      setSelectedStoreId(null);
      setCurrentStore(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete store');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <h2>Store Management</h2>
      
      {error && <ErrorMessage message={error} onDismiss={() => setError(null)} />}

      {/* Current Store Selection */}
      <div style={{
        backgroundColor: '#f5f5f5',
        padding: '1.5rem',
        borderRadius: '8px',
        marginBottom: '2rem'
      }}>
        <h3 style={{ marginTop: 0 }}>Current Store</h3>
        {selectedStoreId ? (
          <div>
            <p style={{ fontSize: '1.2rem', fontWeight: 'bold', color: '#232f3e' }}>
              {selectedStoreId}
            </p>
            <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
              <button
                onClick={handleLoadStore}
                disabled={loading}
                style={{
                  padding: '0.5rem 1rem',
                  backgroundColor: '#ff9900',
                  color: 'white',
                  border: 'none',
                  borderRadius: '4px',
                  cursor: loading ? 'not-allowed' : 'pointer',
                  opacity: loading ? 0.6 : 1
                }}
              >
                Load Details
              </button>
              <button
                onClick={() => setSelectedStoreId(null)}
                disabled={loading}
                style={{
                  padding: '0.5rem 1rem',
                  backgroundColor: '#666',
                  color: 'white',
                  border: 'none',
                  borderRadius: '4px',
                  cursor: loading ? 'not-allowed' : 'pointer',
                  opacity: loading ? 0.6 : 1
                }}
              >
                Clear Selection
              </button>
            </div>
          </div>
        ) : (
          <p style={{ color: '#666' }}>No store selected. Create a new store or enter an existing store ID.</p>
        )}
      </div>

      {/* Store Details */}
      {loading && <LoadingSpinner message="Loading store details..." />}
      
      {currentStore && !loading && (
        <div style={{
          border: '1px solid #ddd',
          borderRadius: '8px',
          padding: '1.5rem',
          marginBottom: '2rem'
        }}>
          <h3 style={{ marginTop: 0 }}>Store Details</h3>
          <div style={{ display: 'grid', gridTemplateColumns: '150px 1fr', gap: '0.5rem' }}>
            <strong>Store ID:</strong>
            <span>{currentStore.store_id}</span>
            
            <strong>Name:</strong>
            <span>{currentStore.name}</span>
            
            {currentStore.description && (
              <>
                <strong>Description:</strong>
                <span>{currentStore.description}</span>
              </>
            )}
            
            <strong>Created:</strong>
            <span>{formatDate(currentStore.created_at)}</span>
            
            <strong>Updated:</strong>
            <span>{formatDate(currentStore.updated_at)}</span>
          </div>
          
          <button
            onClick={handleDeleteStore}
            disabled={loading}
            style={{
              marginTop: '1rem',
              padding: '0.5rem 1rem',
              backgroundColor: '#c00',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: loading ? 'not-allowed' : 'pointer',
              opacity: loading ? 0.6 : 1
            }}
          >
            Delete Store
          </button>
        </div>
      )}

      {/* Create New Store */}
      <div style={{
        border: '1px solid #ddd',
        borderRadius: '8px',
        padding: '1.5rem'
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h3 style={{ margin: 0 }}>Create New Store</h3>
          <button
            onClick={() => setShowCreateForm(!showCreateForm)}
            style={{
              padding: '0.5rem 1rem',
              backgroundColor: '#232f3e',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer'
            }}
          >
            {showCreateForm ? 'Cancel' : 'New Store'}
          </button>
        </div>

        {showCreateForm && (
          <form onSubmit={handleCreateStore} style={{ marginTop: '1.5rem' }}>
            <div style={{ marginBottom: '1rem' }}>
              <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 'bold' }}>
                Store ID *
              </label>
              <input
                type="text"
                value={newStoreId}
                onChange={(e) => setNewStoreId(e.target.value)}
                placeholder="my-store-123"
                required
                style={{
                  width: '100%',
                  padding: '0.5rem',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                  fontSize: '1rem'
                }}
              />
              <small style={{ color: '#666' }}>
                Alphanumeric characters, hyphens, and underscores only
              </small>
            </div>

            <div style={{ marginBottom: '1rem' }}>
              <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 'bold' }}>
                Store Name *
              </label>
              <input
                type="text"
                value={newStoreName}
                onChange={(e) => setNewStoreName(e.target.value)}
                placeholder="My Store"
                required
                style={{
                  width: '100%',
                  padding: '0.5rem',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                  fontSize: '1rem'
                }}
              />
            </div>

            <div style={{ marginBottom: '1rem' }}>
              <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 'bold' }}>
                Description
              </label>
              <textarea
                value={newStoreDescription}
                onChange={(e) => setNewStoreDescription(e.target.value)}
                placeholder="Optional description"
                rows={3}
                style={{
                  width: '100%',
                  padding: '0.5rem',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                  fontSize: '1rem',
                  resize: 'vertical'
                }}
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              style={{
                padding: '0.75rem 1.5rem',
                backgroundColor: '#ff9900',
                color: 'white',
                border: 'none',
                borderRadius: '4px',
                cursor: loading ? 'not-allowed' : 'pointer',
                fontSize: '1rem',
                fontWeight: 'bold',
                opacity: loading ? 0.6 : 1
              }}
            >
              {loading ? 'Creating...' : 'Create Store'}
            </button>
          </form>
        )}
      </div>

      {/* Manual Store Selection */}
      <div style={{
        border: '1px solid #ddd',
        borderRadius: '8px',
        padding: '1.5rem',
        marginTop: '2rem'
      }}>
        <h3 style={{ marginTop: 0 }}>Select Existing Store</h3>
        <p style={{ color: '#666', marginBottom: '1rem' }}>
          Enter a store ID to work with an existing store
        </p>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <input
            type="text"
            placeholder="Enter store ID"
            onKeyPress={(e) => {
              if (e.key === 'Enter') {
                const input = e.target as HTMLInputElement;
                if (input.value.trim()) {
                  setSelectedStoreId(input.value.trim());
                  input.value = '';
                }
              }
            }}
            style={{
              flex: 1,
              padding: '0.5rem',
              border: '1px solid #ddd',
              borderRadius: '4px',
              fontSize: '1rem'
            }}
          />
          <button
            onClick={(e) => {
              const input = (e.target as HTMLButtonElement).previousElementSibling as HTMLInputElement;
              if (input.value.trim()) {
                setSelectedStoreId(input.value.trim());
                input.value = '';
              }
            }}
            style={{
              padding: '0.5rem 1.5rem',
              backgroundColor: '#232f3e',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer'
            }}
          >
            Select
          </button>
        </div>
      </div>
    </div>
  );
};
