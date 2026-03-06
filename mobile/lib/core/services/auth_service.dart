import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'token_service.dart';
import 'secure_storage_service.dart';
import 'config_service.dart';
// Import AppConfig if you want to clear cached API key on logout:
// import '../config/app_config.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final ConfigService _configService = ConfigService();
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _hasSeenWelcomeKey = 'has_seen_welcome';

  void _log(String message) {
    print('🔍 [AUTH] $message');
  }

  /// Fetch app configuration in background after login
  /// This fetches the Gemini API key from the database and caches it locally
  void _fetchConfigInBackground() {
    // Run in background - don't await to avoid blocking login flow
    _configService.fetchAndCacheGeminiApiKey().then((apiKey) {
      if (apiKey != null) {
        _log('✅ [AUTH] Gemini API key fetched from database');
      } else {
        _log('⚠️ [AUTH] Using fallback Gemini API key (database fetch failed or empty)');
      }
    }).catchError((e) {
      _log('⚠️ [AUTH] Failed to fetch Gemini API key from database: $e');
      // App will continue using fallback API key
    });
  }

  // Login with email and password
  Future<UserModel> login(String email, String password) async {
    _log('🔐 [AUTH] Attempting login for: $email');
    try {
      final response = await _apiService.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _log('✅ [AUTH] Login successful');

        // Save tokens
        await _tokenService.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        _log('💾 [AUTH] Tokens saved');

        // Create user model from response
        final userData = data['user'] ?? data;

        // Convert role string to enum
        UserRole role = UserRole.patient;
        final roleStr = (userData['role'] ?? 'patient')
            .toString()
            .toLowerCase();
        if (roleStr == 'caregiver') {
          role = UserRole.caregiver;
        }

        // Convert subscription tier string to enum
        SubscriptionTier subscriptionTier = SubscriptionTier.free;
        final tierStr = (userData['subscriptionTier'] ?? 'free')
            .toString()
            .toLowerCase();
        if (tierStr == 'premium') {
          subscriptionTier = SubscriptionTier.premium;
        }

        final user = UserModel(
          id:
              userData['id']?.toString() ??
              userData['userId']?.toString() ??
              '',
          email: userData['email']?.toString() ?? '',
          name:
              userData['name']?.toString() ??
              userData['full_name']?.toString() ??
              '',
          role: role,
          subscriptionTier: subscriptionTier,
          age: userData['age']?.toString(),
          medicalConditions: userData['medicalConditions']?.toString(),
          emergencyContact: userData['emergencyContact']?.toString(),
          phone: userData['phone']?.toString(),
          avatarUrl: userData['avatarUrl']?.toString().trim(),
        );

        // Save user to shared preferences
        await _saveUser(user);
        // Mark welcome screen as seen after successful login
        await setWelcomeScreenSeen();
        _log('💾 [AUTH] User saved: ${user.phone ?? user.email} (${user.id})');

        // Fetch and cache Gemini API key from database (non-blocking)
        // This runs in background and doesn't affect login flow
        _fetchConfigInBackground();

        return user;
      } else {
        _log('❌ [AUTH] Login failed: ${response.statusMessage}');
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ [AUTH] Login error: $e');
      throw Exception(e.toString());
    }
  }

  // Register new user
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required UserRole role,
    String? phone,
    String? caregiverInviteCode,
  }) async {
    final trimmedPhone =
        phone != null && phone.trim().isNotEmpty ? phone.trim() : null;
    _log('📝 [AUTH] Attempting registration for: $email');

    // Client-side validation
    if (name.isEmpty || password.isEmpty || email.trim().isEmpty) {
      _log('❌ [AUTH] Registration validation failed: Name, email and password are required');
      throw Exception('Name, email and password are required');
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
      _log('❌ [AUTH] Registration validation failed: Invalid email format');
      throw Exception('Please enter a valid email address');
    }

    // Validate phone format if provided
    if (trimmedPhone != null && trimmedPhone.isNotEmpty) {
      if (!RegExp(r'^\+92\d{10}$').hasMatch(trimmedPhone)) {
        _log('❌ [AUTH] Registration validation failed: Invalid phone format');
        throw Exception('Phone must be in format +92XXXXXXXXXX');
      }
    }

    if (password != confirmPassword) {
      _log('❌ [AUTH] Registration validation failed: Passwords do not match');
      throw Exception('Passwords do not match');
    }

    if (password.length < 8) {
      _log('❌ [AUTH] Registration validation failed: Password too short');
      throw Exception('Password must be at least 8 characters');
    }

    final payloadRole = role == UserRole.caregiver ? 'caregiver' : 'patient';

    try {
      final requestBody = {
        'password': password,
        'name': name.trim(),
        'email': email.trim(),
        'roleCode': payloadRole,
        if (trimmedPhone != null && trimmedPhone.isNotEmpty) 'phone': trimmedPhone,
        if (role == UserRole.caregiver && caregiverInviteCode != null)
          'caregiverInviteCode': caregiverInviteCode.trim(),
      };

      final response = await _apiService.post(
        '/auth/register',
        data: requestBody,
      );

      if (response.statusCode == 201) {
        final data = response.data;
        _log('✅ [AUTH] Registration successful: ${data['userId']}');

        // Registration successful - return a user model with the userId
        // Note: Backend returns { message, userId }, not full user object
        // User will need to verify email before logging in
        final responseRole =
            (data['role'] ?? payloadRole).toString().toLowerCase();
        final userRole =
            responseRole == 'caregiver' ? UserRole.caregiver : UserRole.patient;

        final user = UserModel(
          id: data['userId'].toString(),
          email: email,
          name: name,
          role: userRole,
          subscriptionTier: SubscriptionTier.free,
        );

        // Don't save user as logged in yet - they need to verify email
        // Just return the user for UI purposes
        _log('📝 [AUTH] User created (not logged in): ${user.email}');
        return user;
      } else {
        _log('❌ [AUTH] Registration failed: ${response.statusMessage}');
        throw Exception('Registration failed: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ [AUTH] Registration error: $e');
      throw Exception(e.toString());
    }
  }

  // Verify email with token
  Future<bool> verifyEmail(String token) async {
    _log('✉️ [AUTH] Attempting email verification');
    try {
      final response = await _apiService.post(
        '/auth/verify-email',
        data: {'token': token},
      );

      if (response.statusCode == 200) {
        _log('✅ [AUTH] Email verification successful');
        return true;
      } else {
        _log('❌ [AUTH] Email verification failed: ${response.statusMessage}');
        throw Exception('Email verification failed');
      }
    } catch (e) {
      _log('❌ [AUTH] Email verification error: $e');
      throw Exception(e.toString());
    }
  }

  // Resend verification email
  Future<bool> resendVerificationEmail(String email) async {
    _log('📧 [AUTH] Resending verification email to: $email');
    try {
      final response = await _apiService.post(
        '/auth/resend-verification',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        _log('✅ [AUTH] Verification email resent successfully');
        return true;
      } else {
        _log('❌ [AUTH] Failed to resend verification email: ${response.statusMessage}');
        throw Exception('Failed to resend verification email');
      }
    } catch (e) {
      _log('❌ [AUTH] Error resending verification email: $e');
      throw Exception(e.toString());
    }
  }

  // Forgot password - send reset link
  Future<bool> forgotPassword(String email) async {
    _log('🔑 [AUTH] Requesting password reset for: $email');
    try {
      final response = await _apiService.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        _log('✅ [AUTH] Password reset link sent successfully');
        return true;
      } else {
        _log('❌ [AUTH] Failed to send password reset link: ${response.statusMessage}');
        throw Exception('Failed to send password reset link');
      }
    } catch (e) {
      _log('❌ [AUTH] Error requesting password reset: $e');
      throw Exception(e.toString());
    }
  }

  // Reset password
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _log('🔑 [AUTH] Attempting password reset with token');
    try {
      final response = await _apiService.post(
        '/auth/reset-password',
        data: {
          'token': token,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        _log('✅ [AUTH] Password reset successful');
        return true;
      } else {
        _log('❌ [AUTH] Password reset failed: ${response.statusMessage}');
        throw Exception('Password reset failed');
      }
    } catch (e) {
      _log('❌ [AUTH] Error resetting password: $e');
      throw Exception(e.toString());
    }
  }

  // Refresh access token
  Future<void> refreshToken() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _apiService.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _tokenService.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
      } else {
        throw Exception('Token refresh failed');
      }
    } catch (e) {
      await _tokenService.clearTokens();
      throw Exception(e.toString());
    }
  }

  // Get user profile from API
  Future<UserModel> getProfile() async {
    _log('👤 [AUTH] Fetching user profile from API');
    try {
      final response = await _apiService.get('/users/profile');

      if (response.statusCode == 200) {
        final userData = response.data;
        _log('✅ [AUTH] Profile fetched successfully');

        // Convert role string to enum
        UserRole role = UserRole.patient;
        final roleStr = (userData['role'] ?? 'patient')
            .toString()
            .toLowerCase();
        if (roleStr == 'caregiver') {
          role = UserRole.caregiver;
        }

        // Convert subscription tier string to enum
        SubscriptionTier subscriptionTier = SubscriptionTier.free;
        final tierStr = (userData['subscriptionTier'] ?? 'free')
            .toString()
            .toLowerCase();
        if (tierStr == 'premium') {
          subscriptionTier = SubscriptionTier.premium;
        }

        final user = UserModel(
          id: userData['id']?.toString() ?? '',
          email: userData['email']?.toString() ?? '',
          name: userData['name']?.toString() ?? '',
          role: role,
          subscriptionTier: subscriptionTier,
          age: userData['age']?.toString(),
          medicalConditions: userData['medicalConditions']?.toString(),
          emergencyContact: userData['emergencyContact']?.toString(),
          phone: userData['phone']?.toString(),
          avatarUrl: userData['avatarUrl']?.toString().trim(),
        );

        await _saveUser(user);
        return user;
      } else {
        _log('❌ [AUTH] Profile fetch failed: ${response.statusMessage}');
        throw Exception('Profile fetch failed: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ [AUTH] Profile fetch error: $e');
      throw Exception(e.toString());
    }
  }

  // Update user profile
  Future<UserModel> updateProfile({
    String? name,
    String? age,
    String? phoneNumber,
    String? dateOfBirth,
    String? address,
    String? city,
    String? country,
    String? medicalConditions,
    String? emergencyContact,
  }) async {
    _log('📝 [AUTH] Updating user profile');
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phoneNumber != null) {
        data['phoneNumber'] = phoneNumber;
        // Note: Backend only accepts 'phoneNumber', not 'phone'
      }
      if (dateOfBirth != null) data['dateOfBirth'] = dateOfBirth;
      if (address != null) data['address'] = address;
      if (city != null) data['city'] = city;
      if (country != null) data['country'] = country;
      if (medicalConditions != null)
        data['medicalConditions'] = medicalConditions;
      if (emergencyContact != null) data['emergencyContact'] = emergencyContact;
      // Note: Backend doesn't accept 'age' field - age is calculated from dateOfBirth if needed

      final response = await _apiService.patch('/users/profile', data: data);

      if (response.statusCode == 200) {
        _log('✅ [AUTH] Profile updated successfully');
        final userData = response.data;

        // Convert role string to enum
        UserRole role = UserRole.patient;
        final roleStr = (userData['role'] ?? 'patient')
            .toString()
            .toLowerCase();
        if (roleStr == 'caregiver') {
          role = UserRole.caregiver;
        }

        // Convert subscription tier string to enum
        SubscriptionTier subscriptionTier = SubscriptionTier.free;
        final tierStr = (userData['subscriptionTier'] ?? 'free')
            .toString()
            .toLowerCase();
        if (tierStr == 'premium') {
          subscriptionTier = SubscriptionTier.premium;
        }

        final updatedUser = UserModel(
          id: userData['id']?.toString() ?? '',
          email: userData['email']?.toString() ?? '',
          name: userData['name']?.toString() ?? '',
          role: role,
          subscriptionTier: subscriptionTier,
          age: userData['age']?.toString(),
          medicalConditions: userData['medicalConditions']?.toString(),
          emergencyContact: userData['emergencyContact']?.toString(),
          phone: userData['phone']?.toString(),
          avatarUrl: userData['avatarUrl']?.toString().trim(),
        );

        await _saveUser(updatedUser);
        return updatedUser;
      } else {
        _log('❌ [AUTH] Profile update failed: ${response.statusMessage}');
        throw Exception('Profile update failed: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ [AUTH] Profile update error: $e');
      throw Exception(e.toString());
    }
  }

  // Update subscription tier
  Future<UserModel> updateSubscription(SubscriptionTier tier) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // This would typically call a subscription endpoint
    // For now, just update locally
    final updatedUser = currentUser.copyWith(subscriptionTier: tier);
    await _saveUser(updatedUser);
    return updatedUser;
  }

  // Get current logged-in user
  Future<UserModel?> getCurrentUser() async {
    _log('👤 [AUTH] Checking for current user...');
    // Check if we have tokens
    final hasTokens = await _tokenService.hasTokens();
    if (!hasTokens) {
      _log('❌ [AUTH] No tokens found');
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    if (!isLoggedIn) {
      _log('❌ [AUTH] User not logged in');
      return null;
    }

    final userJson = prefs.getString(_userKey);
    if (userJson == null) {
      _log('❌ [AUTH] No user data found');
      return null;
    }

    try {
      final user = UserModel.fromJson(json.decode(userJson));
      _log('✅ [AUTH] Current user found: ${user.email} (${user.id})');
      return user;
    } catch (e) {
      _log('❌ [AUTH] Error parsing user data: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final hasTokens = await _tokenService.hasTokens();
    if (!hasTokens) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Logout
  Future<void> logout() async {
    _log('🚪 [AUTH] Logging out...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
    await _tokenService.clearTokens();
    // Optionally clear biometric credentials (user might want to keep them)
    // await _secureStorage.clearCredentials();
    // Note: We keep the cached Gemini API key for offline use
    // If you want to clear it on logout, uncomment:
    // await AppConfig.clearDatabaseCachedGeminiApiKey();
    _log('✅ [AUTH] Logout complete - tokens and user data cleared');
  }

  // Save user to shared preferences
  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Set welcome screen as seen
  Future<void> setWelcomeScreenSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenWelcomeKey, true);
    _log('✅ [AUTH] Welcome screen marked as seen');
  }

  // Check if welcome screen has been seen
  Future<bool> hasSeenWelcomeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_hasSeenWelcomeKey) ?? false;
    _log('🔍 [AUTH] Welcome screen seen status: $hasSeen');
    return hasSeen;
  }

  // Save credentials for biometric login for a specific user
  Future<void> saveCredentialsForBiometric({
    required String userId,
    required String phone,
    required String password,
  }) async {
    _log('💾 [AUTH] Saving credentials for biometric login for user: $userId');
    try {
      await _secureStorage.saveCredentials(userId: userId, phone: phone, password: password);
      _log('✅ [AUTH] Credentials saved for biometric login for user: $userId');
    } catch (e) {
      _log('❌ [AUTH] Error saving credentials for biometric for user $userId: $e');
      rethrow;
    }
  }

  // Login with biometric authentication for a specific user
  // This method retrieves saved credentials and performs login
  Future<UserModel> loginWithBiometrics(String userId) async {
    _log('🔐 [AUTH] Attempting biometric login for user: $userId');
    try {
      // Check if biometric is enabled and credentials exist for this user
      final hasCredentials = await _secureStorage.hasSavedCredentials(userId);
      if (!hasCredentials) {
        _log('❌ [AUTH] No saved credentials found for biometric login for user: $userId');
        throw Exception('No saved credentials found for this account. Please login with phone and password first.');
      }

      final isEnabled = await _secureStorage.isBiometricEnabled(userId);
      if (!isEnabled) {
        _log('❌ [AUTH] Biometric login is not enabled for user: $userId');
        throw Exception('Biometric login is not enabled for this account');
      }

      // Retrieve saved credentials for this user
      final phone = await _secureStorage.getSavedPhone(userId);
      final password = await _secureStorage.getSavedPassword(userId);

      if (phone == null || password == null || phone.isEmpty || password.isEmpty) {
        _log('❌ [AUTH] Invalid saved credentials for user: $userId');
        throw Exception('Invalid saved credentials for this account');
      }

      _log('✅ [AUTH] Credentials retrieved for user $userId, attempting login...');

      // Use existing login method with retrieved credentials
      return await login(phone, password);
    } catch (e) {
      _log('❌ [AUTH] Biometric login error for user $userId: $e');
      rethrow;
    }
  }

  // Clear biometric credentials for a specific user
  Future<void> clearBiometricCredentials(String userId) async {
    _log('🗑️ [AUTH] Clearing biometric credentials for user: $userId');
    try {
      await _secureStorage.clearCredentials(userId);
      _log('✅ [AUTH] Biometric credentials cleared for user: $userId');
    } catch (e) {
      _log('❌ [AUTH] Error clearing biometric credentials for user $userId: $e');
      rethrow;
    }
  }

  // Check if biometric login is enabled for a specific user
  Future<bool> isBiometricLoginEnabled(String userId) async {
    try {
      final hasCredentials = await _secureStorage.hasSavedCredentials(userId);
      final isEnabled = await _secureStorage.isBiometricEnabled(userId);
      _log('🔍 [AUTH] Biometric login status for user $userId - hasCredentials: $hasCredentials, isEnabled: $isEnabled');
      return hasCredentials && isEnabled;
    } catch (e) {
      _log('❌ [AUTH] Error checking biometric login status for user $userId: $e');
      return false;
    }
  }

  // Get list of user IDs who have biometric login enabled
  Future<List<String>> getUsersWithBiometricEnabled() async {
    try {
      final userIds = await _secureStorage.getUsersWithBiometricEnabled();
      _log('🔍 [AUTH] Found ${userIds.length} users with biometric enabled');
      return userIds;
    } catch (e) {
      _log('❌ [AUTH] Error getting users with biometric enabled: $e');
      return [];
    }
  }
}
