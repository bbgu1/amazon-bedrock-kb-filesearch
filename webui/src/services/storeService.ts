import { Store, CreateStoreRequest, ApiError } from '../types';
import { awsConfig } from '../config/aws';

const API_ENDPOINT = awsConfig.apiGatewayEndpoint;

export class StoreService {
  // Create a new store
  static async createStore(request: CreateStoreRequest): Promise<Store> {
    const response = await fetch(API_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(request)
    });

    if (!response.ok) {
      const error: ApiError = await response.json();
      throw new Error(error.error.message || 'Failed to create store');
    }

    return response.json();
  }

  // Get store by ID
  static async getStore(storeId: string): Promise<Store> {
    const response = await fetch(`${API_ENDPOINT}/${storeId}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      const error: ApiError = await response.json();
      throw new Error(error.error.message || 'Failed to get store');
    }

    return response.json();
  }

  // Update store
  static async updateStore(storeId: string, updates: Partial<Store>): Promise<Store> {
    const response = await fetch(`${API_ENDPOINT}/${storeId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(updates)
    });

    if (!response.ok) {
      const error: ApiError = await response.json();
      throw new Error(error.error.message || 'Failed to update store');
    }

    return response.json();
  }

  // Delete store
  static async deleteStore(storeId: string): Promise<void> {
    const response = await fetch(`${API_ENDPOINT}/${storeId}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      const error: ApiError = await response.json();
      throw new Error(error.error.message || 'Failed to delete store');
    }
  }
}
