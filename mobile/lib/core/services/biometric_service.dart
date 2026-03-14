import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:flutter/services.dart';
import '../config/platform_check_stub.dart'
    if (dart.library.io) '../config/platform_check_io.dart'
    as platform;

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  void _log(String message) {
    print('🔍 [BIOMETRIC] $message');
  }

  /// Check if biometric authentication is available on the device
  Future<bool> isAvailable() async {
    try {
      if (kIsWeb || (!platform.isAndroid && !platform.isIOS)) {
        _log('❌ Biometric authentication not supported on this platform');
        return false;
      }

      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await getAvailableBiometrics();

      // Primary check: canCheckBiometrics OR available biometrics exist
      final hasBiometricCapability =
          canCheckBiometrics || availableBiometrics.isNotEmpty;

      // Secondary check: isDeviceSupported (may fail on some devices even when biometrics work)
      bool isDeviceSupported = false;
      try {
        isDeviceSupported = await _localAuth.isDeviceSupported();
      } catch (e) {
        _log('⚠️ isDeviceSupported() check failed (non-critical): $e');
        // Don't fail if this check fails - use other indicators
      }

      // Consider biometrics available if:
      // 1. canCheckBiometrics is true, OR
      // 2. availableBiometrics list is non-empty, OR
      // 3. isDeviceSupported is true (if check succeeded)
      final isAvailable = hasBiometricCapability || isDeviceSupported;

      _log(
        '🔍 Biometric check - canCheck: $canCheckBiometrics, availableTypes: ${availableBiometrics.length}, deviceSupported: $isDeviceSupported, final: $isAvailable',
      );
      return isAvailable;
    } catch (e) {
      _log('❌ Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types on the device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      _log('✅ Available biometrics: $availableBiometrics');
      return availableBiometrics;
    } catch (e) {
      _log('❌ Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate using biometrics
  /// Returns true if authentication is successful, false otherwise
  Future<bool> authenticate({
    String? localizedReason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      _log('🔐 Starting biometric authentication...');

      if (!await isAvailable()) {
        _log('❌ Biometric authentication not available');
        return false;
      }

      final didAuthenticate = platform.isAndroid
          ? await _localAuth.authenticate(
              localizedReason:
                  localizedReason ?? 'Authenticate to access your account',
              options: AuthenticationOptions(
                useErrorDialogs: useErrorDialogs,
                stickyAuth: stickyAuth,
                biometricOnly: false, // Allow fallback to device credentials
              ),
              authMessages: <AuthMessages>[
                AndroidAuthMessages(
                  signInTitle: 'Biometric Authentication',
                  cancelButton: 'Cancel',
                  biometricHint: 'Verify your identity',
                  biometricNotRecognized: 'Not recognized. Try again.',
                  biometricSuccess: 'Success',
                  deviceCredentialsRequiredTitle: 'Device Credentials Required',
                  deviceCredentialsSetupDescription:
                      'Device credentials required',
                ),
              ],
            )
          : await _localAuth.authenticate(
              localizedReason:
                  localizedReason ?? 'Authenticate to access your account',
              options: AuthenticationOptions(
                useErrorDialogs: useErrorDialogs,
                stickyAuth: stickyAuth,
                biometricOnly: false,
              ),
            );

      if (didAuthenticate) {
        _log('✅ Biometric authentication successful');
      } else {
        _log('❌ Biometric authentication failed or cancelled by user');
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      _log(
        '❌ PlatformException during biometric authentication: ${e.code} - ${e.message}',
      );
      if (e.code == 'no_fragment_activity') {
        _log(
          '❌ CRITICAL: MainActivity must extend FlutterFragmentActivity, not FlutterActivity',
        );
      }
      return false;
    } catch (e) {
      _log('❌ Error during biometric authentication: $e');
      return false;
    }
  }

  /// Stop any ongoing authentication
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      _log('🛑 Biometric authentication stopped');
    } catch (e) {
      _log('❌ Error stopping authentication: $e');
    }
  }
}
