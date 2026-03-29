import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// Custom exception for AI API errors with user-friendly messages
class AIAnalysisException implements Exception {
  final String message;
  final int? statusCode;
  final String? userMessage;

  AIAnalysisException(this.message, {this.statusCode, this.userMessage});

  @override
  String toString() => userMessage ?? message;
}

/// Service for interacting with OpenRouter API to analyze food descriptions
/// and calculate calories, as well as analyze exercise descriptions and
/// calculate calories burned
class AIAnalysisService {
  static AIAnalysisService? _instance;
  Dio? _dio;
  String? _apiKey;
  static const String _aiBaseUrl = 'https://openrouter.ai/api/v1';

  // Try these models in order until one works
  static const List<String> _aiModels = [
    'openai/gpt-oss-20b:free', // User preferred model (also in DB)
    'google/gemini-2.0-flash-exp:free', // Fast and free
    'google/gemini-flash-1.5-8b', // Backup free model
    'openai/gpt-4o-mini', // Very efficient paid model
    'meta-llama/llama-3.1-8b-instruct:free',
  ];
  static String _currentModel = _aiModels[0];

  factory AIAnalysisService() {
    _instance ??= AIAnalysisService._internal();
    return _instance!;
  }

  AIAnalysisService._internal();

  void _log(String message) {
    print('🔍 [AI_ANALYSIS] $message');
  }

  /// Make API request with retry logic for rate limits and overloaded errors
  Future<Response> _makeRequestWithRetry(
    String model,
    Map<String, dynamic> requestData, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        final response = await _dio!.post(
          '/chat/completions',
          data: {
            'model': model,
            ...requestData,
          },
        );

        if (response.statusCode == 200) {
          return response;
        }
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;

        // Handle 429 (Rate Limit) and 503 (Service Overloaded)
        if (statusCode == 429 || statusCode == 503) {
          attempt++;
          if (attempt >= maxRetries) {
            throw AIAnalysisException(
              'The AI service is currently busy. Please try again in a few moments.',
              statusCode: statusCode,
              userMessage:
                  'The AI service is temporarily busy. Please wait a moment and try again.',
            );
          }

          _log(
            '⚠️ Model $model returned $statusCode. Retrying in ${delay.inSeconds}s... (Attempt $attempt/$maxRetries)',
          );
          await Future.delayed(delay);

          // Exponential backoff
          delay = Duration(seconds: delay.inSeconds * 2);
          continue;
        }

        // Re-throw other errors immediately
        rethrow;
      }
    }

    throw AIAnalysisException(
      'Failed to get response after $maxRetries attempts',
      statusCode: 503,
      userMessage:
          'The AI service is temporarily unavailable. Please try again later.',
    );
  }

  /// Get AI API key from configuration (prioritizes consolidated ai_api_key)
  Future<String?> _getApiKey() async {
    // Try to get the consolidated AI key first
    var apiKey = await AppConfig.getGeminiApiKey(); // Still using this name for now but it will hold the OpenRouter key

    if (apiKey == null || apiKey.isEmpty) {
      _log('❌ AI API key not configured');
      return null;
    }
    return apiKey;
  }

  /// Initialize Dio client for OpenRouter API
  Future<void> _ensureInitialized() async {
    if (_dio != null && _apiKey != null) return;

    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception(
        'AI API key not configured. Please set the AI key in your dashboard settings.',
      );
    }

    _apiKey = apiKey;
    
    // Masked logging for debugging (useful for 401 troubleshooting)
    final maskedKey = _apiKey!.length > 15 
        ? '${_apiKey!.substring(0, 10)}...${_apiKey!.substring(_apiKey!.length - 4)}'
        : '***';
    _log('🔑 Using AI API Key: $maskedKey (length: ${_apiKey!.length})');

    _dio = Dio(
      BaseOptions(
        baseUrl: _aiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://digital-nurse-project.site', // Required by OpenRouter for some models
          'X-Title': 'Digital Nurse AI',
        },
      ),
    );

    _log('✅ AI service initialized (OpenRouter)');

    // Check for preferred model to log it
    final preferredModel = await AppConfig.getAiModel();
    if (preferredModel != null && preferredModel.isNotEmpty) {
      _log('🎯 Using preferred model from config: $preferredModel');
    }
    
    _log('📌 Using base URL: $_aiBaseUrl');
  }

  /// Get list of models to try, with preferred model from config first
  Future<List<String>> _getEffectiveModels() async {
    final effectiveModels = <String>[];

    // 1. Get preferred model from database/environment
    final preferredModel = await AppConfig.getAiModel();
    if (preferredModel != null && preferredModel.isNotEmpty) {
      effectiveModels.add(preferredModel);
    }

    // 2. Add fallback models that aren't already in the list
    for (final model in _aiModels) {
      if (!effectiveModels.contains(model)) {
        effectiveModels.add(model);
      }
    }

    return effectiveModels;
  }

  /// Analyze food description and calculate total calories
  /// Returns the estimated calorie count, or null if unable to calculate
  Future<int?> analyzeFoodCalories(String foodDescription) async {
    if (foodDescription.trim().isEmpty) {
      _log('❌ Empty food description provided');
      return null;
    }

    try {
      await _ensureInitialized();
      if (_dio == null) {
        throw Exception('AI service not initialized');
      }

      _log(
        '🤖 Analyzing food description: ${foodDescription.substring(0, foodDescription.length > 50 ? 50 : foodDescription.length)}...',
      );

      // Create prompt for calorie analysis
      final prompt = _buildCalorieAnalysisPrompt(foodDescription);

      // Try different models until one works
      DioException? lastError;
      AIAnalysisException? lastApiException;

      final effectiveModels = await _getEffectiveModels();

      for (final model in effectiveModels) {
        try {
          _log('🔄 Trying model: $model');

          final requestData = {
            'messages': [
              {
                'role': 'user',
                'content':
                    'You are a nutrition expert. Analyze food descriptions and provide accurate calorie estimates. Return ONLY valid JSON. Do NOT include "Here is the JSON" or any other text.\n\n$prompt',
              },
            ],
            'temperature': 0.1,
            'max_tokens': 1000,
            'response_format': {'type': 'json_object'},
          };

          final response = await _makeRequestWithRetry(model, requestData);

          _currentModel = model; // Save working model
          _log('✅ Successfully using model: $model');
          final data = response.data;

          // Extract content from OpenAI/OpenRouter response
          String? content;
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final firstChoice = choices[0] as Map<String, dynamic>?;
            final message = firstChoice?['message'] as Map<String, dynamic>?;
            content = message?['content'] as String?;
          }

          if (content != null && content.isNotEmpty) {
            final result = _parseCalorieResponse(content);
            if (result != null) {
              _log('✅ Calories calculated: $result kcal');
              return result;
            }
          } else {
            _log('⚠️ No content found in response.');
          }
        } on AIAnalysisException catch (e) {
          lastApiException = e;
          _log('⚠️ Model $model failed: ${e.message}');
          continue;
        } on DioException catch (e) {
          lastError = e;
          _log('⚠️ Model $model error: ${e.message}');
          continue;
        }
      }

      // If all models failed
      if (lastApiException != null) throw lastApiException;
      if (lastError != null) {
        throw AIAnalysisException(
          'Unable to analyze food. Please try again or enter calories manually.',
          statusCode: lastError.response?.statusCode,
        );
      }

      throw AIAnalysisException('No available models found for analysis.');
    } catch (e) {
      _log('❌ Error analyzing food calories: $e');
      if (e is AIAnalysisException) rethrow;
      throw AIAnalysisException(
        e.toString(),
        userMessage: 'Unable to analyze food at this time.',
      );
    }
  }
  /// Analyze exercise description and duration to calculate calories burned
  /// Returns the estimated calories burned, or null if unable to calculate
  Future<int?> analyzeExerciseCalories(
    String exerciseDescription,
    int durationMinutes,
  ) async {
    if (exerciseDescription.trim().isEmpty) {
      _log('❌ Empty exercise description provided');
      return null;
    }

    if (durationMinutes <= 0) {
      _log('❌ Invalid duration provided: $durationMinutes');
      return null;
    }

    try {
      await _ensureInitialized();
      if (_dio == null) {
        throw Exception('AI service not initialized');
      }

      _log(
        '🤖 Analyzing exercise: ${exerciseDescription.substring(0, exerciseDescription.length > 50 ? 50 : exerciseDescription.length)}... for $durationMinutes minutes',
      );

      // Create prompt for exercise calorie analysis
      final prompt = _buildExerciseCalorieAnalysisPrompt(
        exerciseDescription,
        durationMinutes,
      );

      // Try different models until one works
      DioException? lastError;
      AIAnalysisException? lastApiException;

      final effectiveModels = await _getEffectiveModels();

      for (final model in effectiveModels) {
        try {
          _log('🔄 Trying model: $model');

          final requestData = {
            'messages': [
              {
                'role': 'user',
                'content':
                    'You are a fitness and exercise expert. Analyze exercise descriptions and calculate accurate calorie burn estimates based on duration. Return ONLY valid JSON. Do NOT include "Here is the JSON" or any other text.\n\n$prompt',
              },
            ],
            'temperature': 0.1,
            'max_tokens': 1000,
            'response_format': {'type': 'json_object'},
          };

          final response = await _makeRequestWithRetry(model, requestData);

          _currentModel = model; // Save working model
          _log('✅ Successfully using model: $model');
          final data = response.data;

          // Extract content from OpenAI/OpenRouter response
          String? content;
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final firstChoice = choices[0] as Map<String, dynamic>?;
            final message = firstChoice?['message'] as Map<String, dynamic>?;
            content = message?['content'] as String?;
          }

          if (content != null && content.isNotEmpty) {
            final result = _parseCalorieResponse(content);
            if (result != null) {
              _log('✅ Calories burned calculated: $result kcal');
              return result;
            }
          } else {
            _log('⚠️ No content found in response.');
          }
        } on AIAnalysisException catch (e) {
          lastApiException = e;
          _log('⚠️ Model $model failed: ${e.message}');
          continue;
        } on DioException catch (e) {
          lastError = e;
          _log('⚠️ Model $model error: ${e.message}');
          continue;
        }
      }

      if (lastApiException != null) throw lastApiException;
      if (lastError != null) {
        throw AIAnalysisException(
          'Unable to analyze exercise. Please try again or enter calories manually.',
          statusCode: lastError.response?.statusCode,
        );
      }

      throw AIAnalysisException('No available models found for analysis.');
    } catch (e) {
      _log('❌ Error analyzing exercise calories: $e');
      if (e is AIAnalysisException) rethrow;
      throw AIAnalysisException(
        e.toString(),
        userMessage: 'Unable to analyze exercise at this time.',
      );
    }
  }

  /// Build prompt for exercise calorie analysis
  String _buildExerciseCalorieAnalysisPrompt(
    String exerciseDescription,
    int durationMinutes,
  ) {
    return '''Analyze the following exercise description and calculate the total estimated calories burned.

Exercise description: "$exerciseDescription"
Duration: $durationMinutes minutes

Please provide your response as JSON with the following format:
{
  "calories": <estimated_total_calories_burned>,
  "intensity": "low" | "moderate" | "high",
  "confidence": "high" | "medium" | "low",
  "notes": "any relevant notes about the estimation"
}

Guidelines:
- Calculate calories burned based on the exercise type and duration
- Consider the intensity level mentioned or implied in the description
- Use standard calorie burn rates for common exercises
- For average body weight (assume 70kg/154lbs if not specified)
- Provide your best estimate even if details are limited
- Return ONLY the JSON object, no text before or after, no markdown, no code blocks

Response (JSON only):''';
  }

  /// Build prompt for calorie analysis
  String _buildCalorieAnalysisPrompt(String foodDescription) {
    return '''Analyze the following food description and calculate the total estimated calories.

Food description: "$foodDescription"

Please provide your response as JSON with the following format:
{
  "calories": <estimated_total_calories>,
  "breakdown": [optional array of individual items if multiple foods mentioned],
  "confidence": "high" | "medium" | "low",
  "notes": "any relevant notes about the estimation"
}

Guidelines:
- If serving size is not mentioned, assume standard serving sizes
- If multiple food items are mentioned, calculate total calories for all items
- Provide your best estimate even if details are limited
- Return ONLY the JSON object, no text before or after, no markdown, no code blocks

Response (JSON only):''';
  }

  /// Parse AI response to extract calorie count
  int? _parseCalorieResponse(String jsonContent) {
    try {
      _log(
        '📝 Raw response content (length: ${jsonContent.length}): ${jsonContent.substring(0, jsonContent.length > 200 ? 200 : jsonContent.length)}${jsonContent.length > 200 ? "..." : ""}',
      );

      // Clean up the response - extract JSON from markdown code blocks or text
      String cleanContent = jsonContent.trim();

      // If content is too short or doesn't contain JSON-like characters, it might be incomplete
      if (cleanContent.length < 5 ||
          (!cleanContent.contains('{') && !cleanContent.contains('['))) {
        _log(
          '⚠️ Response appears incomplete or missing JSON. Full content: $cleanContent',
        );
        return null;
      }

      // Remove markdown code blocks (```json or ```)
      if (cleanContent.contains('```json')) {
        final startIndex = cleanContent.indexOf('```json') + 7;
        final endIndex = cleanContent.lastIndexOf('```');
        if (endIndex > startIndex) {
          cleanContent = cleanContent.substring(startIndex, endIndex).trim();
        }
      } else if (cleanContent.contains('```')) {
        final startIndex = cleanContent.indexOf('```') + 3;
        final endIndex = cleanContent.lastIndexOf('```');
        if (endIndex > startIndex) {
          cleanContent = cleanContent.substring(startIndex, endIndex).trim();
        }
      }

      // Find first '{' and last '}'
      final jsonStartIndex = cleanContent.indexOf('{');
      final jsonEndIndex = cleanContent.lastIndexOf('}');
      if (jsonStartIndex >= 0 && jsonEndIndex > jsonStartIndex) {
        cleanContent = cleanContent.substring(jsonStartIndex, jsonEndIndex + 1);
      }

      final json = jsonDecode(cleanContent) as Map<String, dynamic>;

      // Try to get calories from the response
      final calories = json['calories'];

      if (calories != null) {
        if (calories is int) {
          return calories;
        } else if (calories is num) {
          return calories.round();
        } else if (calories is String) {
          final parsed = int.tryParse(calories);
          if (parsed != null) return parsed;
        }
      }

      _log('❌ Unable to parse calories from response JSON');
      return null;
    } catch (e) {
      _log('❌ Error parsing AI response: $e');
      return null;
    }
  }
}
