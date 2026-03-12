/**
 * Authentication Context
 * Provides global authentication state and methods
 */

import {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
} from 'react';
import type { ReactNode } from 'react';
import type { User, LoginResponse } from '@/types/auth';
import { api, API_ENDPOINTS, ApiClientError } from '@/lib/api/client';
import { setTokens, clearTokens, getAccessToken } from '@/lib/utils/token-storage';

export interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

interface AuthProviderProps {
  children: ReactNode;
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<User | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  /**
   * Initialize auth state from sessionStorage on mount
   */
  useEffect(() => {
    const initAuth = async () => {
      try {
        const token = getAccessToken();
        if (token) {
          // Token exists, try to fetch user info to verify it's valid
          // For now, we'll just set authenticated to true
          // In a production app, you'd want to call /users/me to verify the token
          setIsAuthenticated(true);
        } else {
          setIsAuthenticated(false);
        }
      } catch (error) {
        console.error('Failed to initialize auth:', error);
        clearTokens();
        setIsAuthenticated(false);
      } finally {
        setIsLoading(false);
      }
    };

    initAuth();
  }, []);

  /**
   * Login function
   */
  const login = useCallback(
    async (email: string, password: string): Promise<void> => {
      try {
        setIsLoading(true);

        // Call login API
        const response = await api.post<LoginResponse>(
          API_ENDPOINTS.auth.login,
          { email, password },
          { requireAuth: false },
        );

        // Store tokens
        setTokens(response.accessToken, response.refreshToken);

        // Update state
        setUser(response.user);
        setIsAuthenticated(true);
      } catch (error) {
        // Clear any partial state
        clearTokens();
        setUser(null);
        setIsAuthenticated(false);

        // Re-throw error for handling in component
        if (error instanceof ApiClientError) {
          throw error;
        }
        throw new Error('An unexpected error occurred during login');
      } finally {
        setIsLoading(false);
      }
    },
    [],
  );

  /**
   * Logout function
   */
  const logout = useCallback(() => {
    clearTokens();
    setUser(null);
    setIsAuthenticated(false);
  }, []);

  const value: AuthContextType = {
    user,
    isAuthenticated,
    isLoading,
    login,
    logout,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

/**
 * Hook to use auth context
 */
export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
