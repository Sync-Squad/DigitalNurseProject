import 'api_service.dart';
import '../config/app_config.dart';

/// Service for fetching application configuration from the backend database
class ConfigService {
  final ApiService _apiService = ApiService();

  void _log(String message) {
    print('🔍 [CONFIG_SERVICE] $message');
  }

  /// Fetch Gemini API key from the database and cache it locally
  /// Returns the API key if successful, null otherwise
  /// This should be called after successful login
  Future<String?> fetchAndCacheGeminiApiKey() async {
    _log('🔑 Fetching Gemini API key from database...');
    try {
      final response = await _apiService.get('/config/gemini-api-key');

      if (response.statusCode == 200) {
        final data = response.data;
        final apiKey =
            data['apiKey']?.toString() ?? data['config_value']?.toString();

        if (apiKey != null && apiKey.isNotEmpty) {
          // Cache the API key locally
          await AppConfig.cacheGeminiApiKeyFromDatabase(apiKey);
          _log('✅ Gemini API key fetched and cached successfully');
          return apiKey;
        } else {
          _log('⚠️ API key not found in response');
          return null;
        }
      } else {
        _log('❌ Failed to fetch API key: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _log('❌ Error fetching Gemini API key: $e');
      // Don't throw - just return null and let the app use fallback
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

        // Cache Gemini API key if present
        if (config.containsKey('gemini_api_key')) {
          await AppConfig.cacheGeminiApiKeyFromDatabase(
            config['gemini_api_key']!,
          );
          _log('✅ Gemini API key cached from config');
        }
      } else {
        _log('❌ Failed to fetch config: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ Error fetching app config: $e');
    }

    return config;
  }

  /// Update Gemini API key in the database
  /// Returns true if successful, false otherwise
  Future<bool> updateGeminiApiKey(String apiKey) async {
    _log('🔑 Updating Gemini API key in database...');
    try {
      final response = await _apiService.put(
        '/config/gemini-api-key',
        data: {'apiKey': apiKey},
      );

      if (response.statusCode == 200) {
        // Clear old cached key and cache the new one
        await AppConfig.clearDatabaseCachedGeminiApiKey();
        await AppConfig.cacheGeminiApiKeyFromDatabase(apiKey);
        _log('✅ Gemini API key updated and cached successfully');
        return true;
      } else {
        _log('❌ Failed to update API key: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _log('❌ Error updating Gemini API key: $e');
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
