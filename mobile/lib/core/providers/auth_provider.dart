import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUser();
      // If user is already logged in, ensure welcome screen flag is set
      if (_currentUser != null) {
        await _authService.setWelcomeScreenSeen();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(email, password);
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required UserRole role,
    String? phone,
    String? caregiverInviteCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Register returns user but doesn't log them in
      // User needs to verify email first
      await _authService.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        role: role,
        phone: phone,
        caregiverInviteCode: caregiverInviteCode,
      );
      // Log out any previously logged-in user to clear their session
      // This prevents the router from redirecting to /home and loading old user data
      await logout();
      // Mark welcome screen as seen after successful registration
      await _authService.setWelcomeScreenSeen();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify email
  Future<bool> verifyEmail(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.verifyEmail(token);
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Resend verification email
  Future<bool> resendVerificationEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.resendVerificationEmail(email);
      return success;
    } catch (e) {
      _error = _extractErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Forgot password
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.forgotPassword(email);
      return success;
    } catch (e) {
      _error = _extractErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify reset code
  Future<bool> verifyResetCode(String email, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.verifyPasswordResetCode(email, code);
      return success;
    } catch (e) {
      _error = _extractErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password with code
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return success;
    } catch (e) {
      _error = _extractErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? age,
    String? medicalConditions,
    String? emergencyContact,
    String? phone,
    bool? medicineRemindersEnabled,
    bool? healthAlertsEnabled,
    bool? caregiverUpdatesEnabled,
    bool? biometricEnabled,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.updateProfile(
        age: age,
        phoneNumber: phone,
        medicalConditions: medicalConditions,
        emergencyContact: emergencyContact,
        medicineRemindersEnabled: medicineRemindersEnabled,
        healthAlertsEnabled: healthAlertsEnabled,
        caregiverUpdatesEnabled: caregiverUpdatesEnabled,
        biometricEnabled: biometricEnabled,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload profile picture
  Future<bool> uploadProfilePicture(String filePath) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.uploadAvatar(filePath);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update subscription
  Future<bool> updateSubscription(SubscriptionTier tier) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.updateSubscription(tier);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login with biometric authentication for a specific user
  Future<bool> loginWithBiometrics(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First, authenticate with biometrics
      final authenticated = await _biometricService.authenticate(
        localizedReason: 'Authenticate to access your account',
      );

      if (!authenticated) {
        _error = 'Biometric authentication was cancelled. Please try again.';
        return false;
      }

      // If biometric authentication successful, login with saved credentials for this user
      _currentUser = await _authService.loginWithBiometrics(userId);
      return true;
    } on PlatformException catch (e) {
      // Handle PlatformException specifically
      if (e.code == 'no_fragment_activity') {
        _error =
            'Biometric authentication is not properly configured. Please contact support.';
      } else {
        _error = 'Biometric authentication failed: ${e.message ?? e.code}';
      }
      return false;
    } catch (e) {
      _error = _extractErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save credentials for biometric login for a specific user
  Future<bool> saveCredentialsForBiometric({
    required String userId,
    required String phone,
    required String password,
    bool verifyFirst = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (verifyFirst) {
        // First, verify with biometrics before saving
        final authenticated = await _biometricService.authenticate(
          localizedReason: 'Verify your identity to enable biometric login',
        );

        if (!authenticated) {
          _error = 'Biometric verification was cancelled or failed.';
          return false;
        }
      }

      await _authService.saveCredentialsForBiometric(
        userId: userId,
        phone: phone,
        password: password,
      );
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle biometric login for a specific user
  Future<bool> enableBiometric(String userId, bool enable, {String? phone, String? password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (enable) {
        if (phone == null || password == null) {
          _error = 'Credentials are required to enable biometric login';
          return false;
        }
        final success = await saveCredentialsForBiometric(
          userId: userId,
          phone: phone,
          password: password,
        );
        if (success) {
          // Sync to database
          await updateProfile(biometricEnabled: true);
        }
        return success;
      } else {
        await _authService.clearBiometricCredentials(userId);
        // Sync to database
        await updateProfile(biometricEnabled: false);
        return true;
      }
    } catch (e) {
      _error = _extractErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if biometric login is available for a specific user
  Future<bool> isBiometricLoginAvailable(String userId) async {
    try {
      final isAvailable = await _biometricService.isAvailable();
      if (!isAvailable) {
        return false;
      }
      final isEnabled = await _authService.isBiometricLoginEnabled(userId);
      return isEnabled;
    } catch (e) {
      return false;
    }
  }

  // Check if biometric login is available for any user
  Future<bool> isBiometricLoginAvailableForAnyUser() async {
    try {
      final isAvailable = await _biometricService.isAvailable();
      if (!isAvailable) {
        return false;
      }
      final usersWithBiometric = await _authService
          .getUsersWithBiometricEnabled();
      return usersWithBiometric.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get list of user IDs who have biometric login enabled
  Future<List<String>> getUsersWithBiometricEnabled() async {
    try {
      return await _authService.getUsersWithBiometricEnabled();
    } catch (e) {
      return [];
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Extract user-friendly error message
  String _extractErrorMessage(dynamic error) {
    final errorString = error.toString();

    // Handle PlatformException
    if (error is PlatformException) {
      if (error.code == 'no_fragment_activity') {
        return 'Biometric authentication is not properly configured. Please contact support.';
      }
      return error.message ?? error.code;
    }

    // Remove "Exception: " prefix if present
    if (errorString.startsWith('Exception: ')) {
      return errorString.substring(11);
    }

    // Handle common error patterns
    if (errorString.contains('Conflict:')) {
      return errorString.split('Conflict:').last.trim();
    }
    if (errorString.contains('Unauthorized:')) {
      return errorString.split('Unauthorized:').last.trim();
    }
    if (errorString.contains('Bad request:')) {
      return errorString.split('Bad request:').last.trim();
    }

    return errorString;
  }

  // Change password for logged in user
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return success;
    } catch (e) {
      _error = _extractErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
