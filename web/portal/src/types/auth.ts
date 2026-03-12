/**
 * Authentication Type Definitions
 */

export type LoginRequest = {
  email: string;
  password: string;
};

export type User = {
  id: string;
  email: string;
  phone: string | null;
  name: string;
  role: string;
};

export type LoginResponse = {
  accessToken: string;
  refreshToken: string;
  user: User;
};

export type AuthState = {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
};
