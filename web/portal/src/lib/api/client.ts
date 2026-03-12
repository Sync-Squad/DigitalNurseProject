/**
 * API Client
 * HTTP client wrapper using native fetch with authentication support
 */

import { API_BASE_URL, API_ENDPOINTS } from './config';
import { getAccessToken, clearTokens } from '../utils/token-storage';

export interface ApiError {
  message: string;
  status: number;
  data?: any;
}

export class ApiClientError extends Error {
  status: number;
  data?: any;

  constructor(message: string, status: number, data?: any) {
    super(message);
    this.name = 'ApiClientError';
    this.status = status;
    this.data = data;
  }
}

interface RequestOptions extends RequestInit {
  requireAuth?: boolean;
}

/**
 * Make an authenticated API request
 */
export async function apiRequest<T>(
  endpoint: string,
  options: RequestOptions = {}
): Promise<T> {
  const { requireAuth = true, headers = {}, ...fetchOptions } = options;

  // Build full URL
  const fullUrl = endpoint.startsWith('http')
    ? endpoint
    : `${API_BASE_URL}${endpoint.startsWith('/') ? endpoint : `/${endpoint}`}`;

  // Prepare headers as a record to allow dynamic assignment
  const requestHeaders: Record<string, string> = {
    'Content-Type': 'application/json',
    Accept: 'application/json',
    ...(headers as Record<string, string>),
  };

  // Add authorization token if required
  if (requireAuth) {
    const token = getAccessToken();
    if (token) {
      requestHeaders['Authorization'] = `Bearer ${token}`;
    } else {
      // If auth is required but no token exists, clear tokens and throw error
      clearTokens();
      throw new ApiClientError('No authentication token found', 401);
    }
  }

  try {
    const response = await fetch(fullUrl, {
      ...fetchOptions,
      headers: requestHeaders,
    });

    // Handle non-JSON responses
    const contentType = response.headers.get('content-type');
    const isJson = contentType?.includes('application/json');

    let data: any;
    if (isJson) {
      data = await response.json();
    } else {
      data = await response.text();
    }

    // Handle error responses
    if (!response.ok) {
      // If unauthorized, clear tokens
      if (response.status === 401) {
        clearTokens();
      }

      const errorMessage =
        data?.message ||
        data?.error ||
        `Request failed with status ${response.status}`;

      throw new ApiClientError(errorMessage, response.status, data);
    }

    return data as T;
  } catch (error) {
    if (error instanceof ApiClientError) {
      throw error;
    }

    // Handle network errors
    if (error instanceof TypeError && error.message === 'Failed to fetch') {
      throw new ApiClientError(
        'Network error: Please check your connection',
        0,
      );
    }

    throw new ApiClientError(
      error instanceof Error ? error.message : 'An unexpected error occurred',
      0,
    );
  }
}

/**
 * Convenience methods for common HTTP verbs
 */
export const api = {
  get: <T>(endpoint: string, options?: RequestOptions) =>
    apiRequest<T>(endpoint, { ...options, method: 'GET' }),

  post: <T>(endpoint: string, data?: any, options?: RequestOptions) =>
    apiRequest<T>(endpoint, {
      ...options,
      method: 'POST',
      body: data ? JSON.stringify(data) : undefined,
    }),

  put: <T>(endpoint: string, data?: any, options?: RequestOptions) =>
    apiRequest<T>(endpoint, {
      ...options,
      method: 'PUT',
      body: data ? JSON.stringify(data) : undefined,
    }),

  patch: <T>(endpoint: string, data?: any, options?: RequestOptions) =>
    apiRequest<T>(endpoint, {
      ...options,
      method: 'PATCH',
      body: data ? JSON.stringify(data) : undefined,
    }),

  delete: <T>(endpoint: string, options?: RequestOptions) =>
    apiRequest<T>(endpoint, { ...options, method: 'DELETE' }),
};

// Export endpoints for convenience
export { API_ENDPOINTS };
