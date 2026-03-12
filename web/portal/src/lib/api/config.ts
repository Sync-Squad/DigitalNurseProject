/**
 * API Configuration
 * 
 * Centralized configuration for API endpoints and base URLs.
 * Supports environment variables for different deployment environments.
 */

// Get API base URL from environment variable or use default deployed URL
export const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://100.42.177.77:3000/api";

// API endpoints
export const API_ENDPOINTS = {
  // Auth endpoints
  auth: {
    login: "/auth/login",
    register: "/auth/register",
    refreshToken: "/auth/refresh-token",
    logout: "/auth/logout",
    forgotPassword: "/auth/forgot-password",
    resetPassword: "/auth/reset-password",
  },
  // User endpoints
  users: {
    profile: "/users/profile",
    updateProfile: "/users/profile",
    patients: "/users/patients",
    detail: (id: string) => `/users/${id}`,
  },
  // Dashboard endpoints
  dashboard: {
    metrics: "/dashboard/metrics",
    stats: "/dashboard/stats",
  },
  // Caregiver endpoints
  caregivers: {
    list: "/caregivers",
    detail: (id: string) => `/caregivers/${id}`,
    invite: "/caregivers/invite",
    all: "/caregivers/all",
  },
  // Vitals endpoints
  vitals: {
    list: "/vitals",
    create: "/vitals",
    trends: "/vitals/trends",
  },
  // Medications endpoints
  medications: {
    list: "/medications",
    create: "/medications",
    update: (id: string) => `/medications/${id}`,
    delete: (id: string) => `/medications/${id}`,
  },
  // Documents endpoints
  documents: {
    list: "/documents",
    upload: "/documents",
    download: (id: string) => `/documents/${id}/download`,
    delete: (id: string) => `/documents/${id}`,
  },
  // Notifications endpoints
  notifications: {
    list: "/notifications",
    markAsRead: (id: string) => `/notifications/${id}/read`,
    markAllAsRead: "/notifications/read-all",
  },
  // Subscriptions endpoints
  subscriptions: {
    active: "/subscriptions/active",
    plans: "/subscriptions/plans",
    current: "/subscriptions/current",
  },
  // Lifestyle endpoints
  lifestyle: {
    summaryWeekly: "/lifestyle/summary/weekly",
    dietPlans: "/lifestyle/diet-plans",
    exercisePlans: "/lifestyle/exercise-plans",
    dietLogs: "/lifestyle/diet",
    exerciseLogs: "/lifestyle/exercise",
  },
} as const;

/**
 * Get full API URL for an endpoint
 * @param endpoint - API endpoint path (e.g., "/auth/login")
 * @returns Full URL with base URL
 */
export function getApiUrl(endpoint: string): string {
  // Remove leading slash if present to avoid double slashes
  const cleanEndpoint = endpoint.startsWith("/") ? endpoint.slice(1) : endpoint;
  const baseUrl = API_BASE_URL.endsWith("/")
    ? API_BASE_URL.slice(0, -1)
    : API_BASE_URL;
  return `${baseUrl}/${cleanEndpoint}`;
}

/**
 * API client configuration options
 */
export interface ApiClientConfig {
  baseURL: string;
  timeout: number;
  headers: Record<string, string>;
}

/**
 * Default API client configuration
 */
export const defaultApiConfig: ApiClientConfig = {
  baseURL: API_BASE_URL,
  timeout: 30000, // 30 seconds
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
  },
};

