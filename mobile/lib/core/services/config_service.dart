import 'api_service.dart';
import '../config/app_config.dart';

/// Service for fetching application configuration from the backend database
class ConfigService {
  final ApiService _apiService = ApiService();

  void _log(String message) {
    print('🔍 [CONFIG_SERVICE] $message');
  }

  /// Fetch AI API key from the database and cache it locally
  /// Returns the API key if successful, null otherwise
  Future<String?> fetchAndCacheGeminiApiKey() async {
    _log('🔑 Fetching AI API key from database...');
    try {
      // First try the new consolidated key
      var response = await _apiService.get('/config/ai-api-key');

      // Fallback to legacy key if not found
      if (response.statusCode != 200) {
        _log('⚠️ ai-api-key not found, falling back to gemini-api-key');
        response = await _apiService.get('/config/gemini-api-key');
      }

      if (response.statusCode == 200) {
        final data = response.data;
        final apiKey =
            data['apiKey']?.toString() ?? data['config_value']?.toString();

        if (apiKey != null && apiKey.isNotEmpty) {
          // Cache the API key locally
          await AppConfig.cacheAiApiKeyFromDatabase(apiKey);
          // Also cache as gemini key for backup/compatibility
          await AppConfig.cacheGeminiApiKeyFromDatabase(apiKey);
          _log('✅ AI API key fetched and cached successfully (length: ${apiKey.length})');
          return apiKey;
        } else {
          _log('⚠️ AI API key found but is EMPTY in response');
          return null;
        }
      } else {
        _log('❌ Server returned ${response.statusCode} for AI API key fetch');
        return null;
      }
    } catch (e) {
      _log('❌ Error fetching AI API key: $e');
      return null;
    }
  }

  /// Fetch all app configuration from database
  /// Can be extended to fetch multiple config values
  Future<Map<String, String>> fetchAppConfig() async {
    _log('📋 Fetching app configuration from database...');
    final config = <String, String>{};

    try {
      final response = await _apiService.get('/config');

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle array of config items
        if (data is List) {
          for (final item in data) {
            final key = item['config_key']?.toString();
            final value = item['config_value']?.toString();
            if (key != null && value != null) {
              config[key] = value;
            }
          }
        }
        // Handle single config object
        else if (data is Map) {
          data.forEach((key, value) {
            if (value != null) {
              config[key.toString()] = value.toString();
            }
          });
        }

        _log('✅ App configuration fetched: ${config.keys.length} items');

        // Cache AI API key if present
        if (config.containsKey('ai_api_key')) {
          await AppConfig.cacheAiApiKeyFromDatabase(config['ai_api_key']!);
          _log('✅ AI API key cached from config');
        } else if (config.containsKey('gemini_api_key')) {
          await AppConfig.cacheAiApiKeyFromDatabase(config['gemini_api_key']!);
          await AppConfig.cacheGeminiApiKeyFromDatabase(config['gemini_api_key']!);
          _log('✅ Gemini API key cached as AI key from config');
        }

        // Cache AI model if present
        if (config.containsKey('ai_model')) {
          await AppConfig.cacheAiModelFromDatabase(config['ai_model']!);
          _log('✅ AI model cached from config: ${config['ai_model']}');
        }
      } else {
        _log('❌ Failed to fetch config: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ Error fetching app config: $e');
    }

    return config;
  }

  /// Update AI API key in the database
  Future<bool> updateGeminiApiKey(String apiKey) async {
    _log('🔑 Updating AI API key in database...');
    try {
      // Update both for safety, but primary is ai-api-key
      final response = await _apiService.put(
        '/config/ai-api-key',
        data: {'config_value': apiKey},
      );

      if (response.statusCode == 200) {
        // Clear old cached key and cache the new one
        await AppConfig.cacheAiApiKeyFromDatabase(apiKey);
        _log('✅ AI API key updated and cached successfully');
        return true;
      } else {
        _log('❌ Failed to update API key: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _log('❌ Error updating AI API key: $e');
      return false;
    }
  }

  /// Clear cached Gemini API key
  /// This forces the app to fetch a new key from the database on next use
  Future<void> clearCachedGeminiApiKey() async {
    _log('🗑️ Clearing cached Gemini API key...');
    await AppConfig.clearDatabaseCachedGeminiApiKey();
    await AppConfig.clearGeminiApiKey();
    _log('✅ Cached Gemini API key cleared');
  }
}
