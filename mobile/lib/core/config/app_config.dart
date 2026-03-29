import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_check_stub.dart'
    if (dart.library.io) 'platform_check_io.dart'
    as platform;

class AppConfig {
  static const String _apiBaseUrlKey = 'api_base_url';
  static const String _aiApiKeyKey = 'ai_api_key';
  static const String _aiApiKeyFromDbKey = 'ai_api_key_from_db';
  static const String _aiModelKey = 'ai_model';
  static const String _aiModelFromDbKey = 'ai_model_from_db';
  static const String _geminiApiKeyKey = 'gemini_api_key'; // Legacy
  static const String _geminiApiKeyFromDbKey = 'gemini_api_key_from_db'; // Legacy

  // Default URLs for different environments
  //static const String _defaultLocalhost = 'http://109.199.126.203:3000/api/';
  //static const String _defaultAndroidEmulator = 'http://109.199.126.203:3000/api/';
  static const String _defaultLocalhost = 'http://localhost:3000/api/';
  static const String _defaultAndroidEmulator = 'http://localhost:3000/api/';

  // Default AI API key (fallback if database fetch fails)
  static const String _defaultAiApiKey = '';

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

  // Get AI API key with priority:
  // 1. Database (cached in SharedPreferences after login/sync)
  // 2. Environment variable
  // 3. User-set preference
  static Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();

    // First priority: Consolidated AI key from DB
    final aiKey = prefs.getString(_aiApiKeyFromDbKey);
    if (aiKey != null && aiKey.isNotEmpty) {
      print('🔍 [CONFIG] Using consolidated AI API key from database');
      return aiKey;
    }

    // Second priority: Legacy Gemini key from DB
    final dbCachedKey = prefs.getString(_geminiApiKeyFromDbKey);
    if (dbCachedKey != null && dbCachedKey.isNotEmpty) {
      print('🔍 [CONFIG] Using legacy Gemini API key from database');
      return dbCachedKey;
    }

    // Third priority: Environment variables
    const orKey = String.fromEnvironment('AI_API_KEY', defaultValue: '');
    if (orKey.isNotEmpty) return orKey;

    const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (envKey.isNotEmpty) return envKey;

    // Check saved preferences
    final savedAiKey = prefs.getString(_aiApiKeyKey);
    if (savedAiKey != null && savedAiKey.isNotEmpty) return savedAiKey;

    final savedKey = prefs.getString(_geminiApiKeyKey);
    if (savedKey != null && savedKey.isNotEmpty) return savedKey;

    return null;
  }

  // Cache AI API key fetched from database
  static Future<void> cacheAiApiKeyFromDatabase(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiApiKeyFromDbKey, key);
    print('✅ [CONFIG] AI API key cached');
  }

  // Cache legacy Gemini key (for backward compatibility)
  static Future<void> cacheGeminiApiKeyFromDatabase(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKeyFromDbKey, key);
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

  // Get AI Model with priority:
  // 1. Database (cached in SharedPreferences after login/sync)
  // 2. Environment variable
  // 3. User-set preference
  static Future<String?> getAiModel() async {
    final prefs = await SharedPreferences.getInstance();

    // First priority: Model from DB
    final aiModel = prefs.getString(_aiModelFromDbKey);
    if (aiModel != null && aiModel.isNotEmpty) {
      print('🔍 [CONFIG] Using AI model from database: $aiModel');
      return aiModel;
    }

    // Second priority: Environment variable
    const envModel = String.fromEnvironment('AI_MODEL', defaultValue: '');
    if (envModel.isNotEmpty) {
      print('🔍 [CONFIG] Using AI model from environment: $envModel');
      return envModel;
    }

    // Third priority: User-set preference
    final savedModel = prefs.getString(_aiModelKey);
    if (savedModel != null && savedModel.isNotEmpty) {
      print('🔍 [CONFIG] Using saved AI model preference: $savedModel');
      return savedModel;
    }

    return null;
  }

  // Cache AI model fetched from database
  static Future<void> cacheAiModelFromDatabase(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiModelFromDbKey, model);
    print('✅ [CONFIG] AI model cached: $model');
  }

  // Clear database-cached AI model
  static Future<void> clearDatabaseCachedAiModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_aiModelFromDbKey);
    print('🗑️ [CONFIG] Database-cached AI model cleared');
  }

  // Set AI model (user preference)
  static Future<void> setAiModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiModelKey, model);
    print('✅ [CONFIG] AI model preference saved: $model');
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
