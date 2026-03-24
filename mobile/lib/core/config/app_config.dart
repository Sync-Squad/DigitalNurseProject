import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_check_stub.dart'
    if (dart.library.io) 'platform_check_io.dart'
    as platform;

class AppConfig {
  static const String _apiBaseUrlKey = 'api_base_url';
  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _geminiApiKeyFromDbKey = 'gemini_api_key_from_db';

  // Default URLs for different environments
  static const String _defaultLocalhost = 'http://109.199.126.203:3000/api/';
  static const String _defaultAndroidEmulator = 'http://109.199.126.203:3000/api/';
  //static const String _defaultLocalhost = 'http://localhost:3000/api/';
  //static const String _defaultAndroidEmulator = 'http://localhost:3000/api/';

  // Default Gemini API key (fallback if database fetch fails)
  // NOTE: This should be empty in production. API keys should come from the database.
  static const String _defaultGeminiApiKey = '';

  // Convert localhost URLs to Android emulator URL (10.0.2.2)
  // This is needed because Android emulators can't access host machine's localhost directly
  // Note: Only converts localhost/127.0.0.1 URLs, not IP addresses
  static String _convertToAndroidEmulatorUrl(String url) {
    // Check if URL contains localhost or 127.0.0.1 (not needed for IP addresses)
    if (url.contains('localhost') || url.contains('127.0.0.1')) {
      // Replace localhost/127.0.0.1 with 10.0.2.2 while preserving port and path
      final converted = url
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
      print(
        '🔄 [CONFIG] Converted localhost URL to Android emulator URL: $url -> $converted',
      );
      return converted;
    }
    // Return as-is for IP addresses (like 100.42.177.77)
    return url;
  }

  // Get API base URL with smart defaults
  static Future<String> getBaseUrl() async {
    String finalUrl;

    // First, check if user has set a custom URL
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_apiBaseUrlKey);

    if (savedUrl != null && savedUrl.isNotEmpty) {
      print('🔍 [CONFIG] Using saved API URL: $savedUrl');
      finalUrl = savedUrl;
    } else {
      // Use environment variable if set
      const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
      if (envUrl.isNotEmpty) {
        print('🔍 [CONFIG] Using environment API URL: $envUrl');
        finalUrl = envUrl;
      } else {
        // Smart defaults based on platform (web-safe: no dart:io on web)
        if (kIsWeb) {
          print('🔍 [CONFIG] Web detected, using API URL: $_defaultLocalhost');
          finalUrl = _defaultLocalhost;
        } else if (platform.isAndroid) {
          print(
            '🔍 [CONFIG] Android detected, using API URL: $_defaultAndroidEmulator',
          );
          finalUrl = _defaultAndroidEmulator;
        } else if (platform.isIOS) {
          print('🔍 [CONFIG] iOS detected, using API URL: $_defaultLocalhost');
          finalUrl = _defaultLocalhost;
        } else {
          print('🔍 [CONFIG] Using default API URL: $_defaultLocalhost');
          finalUrl = _defaultLocalhost;
        }
      }
    }

    // If running on Android and URL contains localhost/127.0.0.1, convert it
    if (!kIsWeb && platform.isAndroid) {
      finalUrl = _convertToAndroidEmulatorUrl(finalUrl);
    }

    return finalUrl;
  }

  // Set custom API base URL (useful for physical devices)
  static Future<void> setApiBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiBaseUrlKey, url);
    print('✅ [CONFIG] API URL saved: $url');
  }

  // Clear custom API base URL
  static Future<void> clearApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiBaseUrlKey);
    print('🗑️ [CONFIG] API URL cleared, will use defaults');
  }

  // Get current API base URL (synchronous for backward compatibility)
  // Note: This will use defaults, not saved URL (web-safe)
  static String get baseUrl {
    if (kIsWeb || !platform.isAndroid) {
      return _defaultLocalhost;
    }
    return _defaultAndroidEmulator;
  }

  // Get base URL for the web/app (for sharing links like invitations)
  // This is usually the same as baseUrl but without the '/api/' suffix
  static String get appBaseUrl {
    final base = baseUrl;
    if (base.endsWith('/api/')) {
      return base.substring(0, base.length - 5);
    } else if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  // Get Gemini API key with priority:
  // 1. Database (cached in SharedPreferences after login)
  // 2. Environment variable
  // 3. User-set preference
  // 4. Hardcoded default (fallback - should be empty in production)
  static Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();

    // First priority: Database cached key (fetched after login)
    final dbCachedKey = prefs.getString(_geminiApiKeyFromDbKey);
    if (dbCachedKey != null && dbCachedKey.isNotEmpty) {
      print('🔍 [CONFIG] Using Gemini API key from database (cached)');
      return dbCachedKey;
    }

    // Second priority: Environment variable
    const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (envKey.isNotEmpty) {
      print('🔍 [CONFIG] Using Gemini API key from environment variable');
      return envKey;
    }

    // Third priority: User-saved preference
    final savedKey = prefs.getString(_geminiApiKeyKey);
    if (savedKey != null && savedKey.isNotEmpty) {
      print('🔍 [CONFIG] Using saved Gemini API key');
      return savedKey;
    }

    // Last resort: Default API key (should be empty in production)
    if (_defaultGeminiApiKey.isNotEmpty) {
      print(
        '⚠️ [CONFIG] Using default Gemini API key (fallback - not recommended for production)',
      );
      return _defaultGeminiApiKey;
    }

    print('⚠️ [CONFIG] Gemini API key not found');
    return null;
  }

  // Cache Gemini API key fetched from database
  // This is called after successful login
  static Future<void> cacheGeminiApiKeyFromDatabase(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKeyFromDbKey, key);
    print('✅ [CONFIG] Gemini API key from database cached');
  }

  // Clear database-cached Gemini API key
  // Call this on logout if you want to force re-fetch on next login
  static Future<void> clearDatabaseCachedGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_geminiApiKeyFromDbKey);
    print('🗑️ [CONFIG] Database-cached Gemini API key cleared');
  }

  // Set Gemini API key (user preference)
  static Future<void> setGeminiApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKeyKey, key);
    print('✅ [CONFIG] Gemini API key saved');
  }

  // Clear Gemini API key (user preference)
  static Future<void> clearGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_geminiApiKeyKey);
    print('🗑️ [CONFIG] Gemini API key cleared');
  }

  // Legacy method for backward compatibility (deprecated)
  @Deprecated('Use getGeminiApiKey() instead')
  static Future<String?> getOpenAIApiKey() async {
    return getGeminiApiKey();
  }

  // Legacy method for backward compatibility (deprecated)
  @Deprecated('Use setGeminiApiKey() instead')
  static Future<void> setOpenAIApiKey(String key) async {
    return setGeminiApiKey(key);
  }

  // Legacy method for backward compatibility (deprecated)
  @Deprecated('Use clearGeminiApiKey() instead')
  static Future<void> clearOpenAIApiKey() async {
    return clearGeminiApiKey();
  }
}
