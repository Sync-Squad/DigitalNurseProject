import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// Custom exception for Gemini API errors with user-friendly messages
class GeminiApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? userMessage;

  GeminiApiException(this.message, {this.statusCode, this.userMessage});

  @override
  String toString() => userMessage ?? message;
}

/// Service for interacting with Google Gemini API to analyze food descriptions
/// and calculate calories, as well as analyze exercise descriptions and
/// calculate calories burned
class OpenAIService {
  static OpenAIService? _instance;
  Dio? _dio;
  String? _apiKey;
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  // Try these models in order until one works
  static const List<String> _geminiModels = [
    'gemini-flash-latest', // Proven working model
    'gemini-2.0-flash-exp', // Latest experimental model
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash-001',
    'gemini-1.5-pro',
    'gemini-1.5-pro-latest',
    'gemini-1.0-pro',
    'gemini-pro',
  ];
  static String _geminiModel = _geminiModels[0];

  factory OpenAIService() {
    _instance ??= OpenAIService._internal();
    return _instance!;
  }

  OpenAIService._internal();

  void _log(String message) {
    print('🔍 [GEMINI] $message');
  }

  /// Make API request with retry logic for 503 (overloaded) errors
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
          '/models/$model:generateContent',
          queryParameters: {'key': _apiKey},
          data: requestData,
        );

        if (response.statusCode == 200) {
          return response;
        }
      } on DioException catch (e) {
        // Handle 503 (Service Unavailable / Overloaded)
        if (e.response?.statusCode == 503) {
          attempt++;
          if (attempt >= maxRetries) {
            throw GeminiApiException(
              'The AI service is currently overloaded. Please try again in a few moments.',
              statusCode: 503,
              userMessage:
                  'The AI service is temporarily busy. Please wait a moment and try again.',
            );
          }

          _log(
            '⚠️ Model $model is overloaded (503). Retrying in ${delay.inSeconds}s... (Attempt $attempt/$maxRetries)',
          );
          await Future.delayed(delay);

          // Exponential backoff: 1s, 2s, 4s
          delay = Duration(seconds: delay.inSeconds * 2);
          continue;
        }

        // Re-throw other errors immediately
        rethrow;
      }
    }

    throw GeminiApiException(
      'Failed to get response after $maxRetries attempts',
      statusCode: 503,
      userMessage:
          'The AI service is temporarily unavailable. Please try again later.',
    );
  }

  /// Get Gemini API key from configuration
  Future<String?> _getApiKey() async {
    final apiKey = await AppConfig.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      _log('❌ Gemini API key not configured');
      return null;
    }
    return apiKey;
  }

  /// Initialize Dio client for Gemini API
  Future<void> _ensureInitialized() async {
    if (_dio != null && _apiKey != null) return;

    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception(
        'Gemini API key not configured. Please set GEMINI_API_KEY environment variable or in app config.',
      );
    }

    _apiKey = apiKey;
    _dio = Dio(
      BaseOptions(
        baseUrl: _geminiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _log('✅ Gemini service initialized');
    _log('📌 Using model: $_geminiModel with API: $_geminiBaseUrl');
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
        throw Exception('Gemini service not initialized');
      }

      _log(
        '🤖 Analyzing food description: ${foodDescription.substring(0, foodDescription.length > 50 ? 50 : foodDescription.length)}...',
      );

      // Create prompt for calorie analysis
      final prompt = _buildCalorieAnalysisPrompt(foodDescription);

      // Try different models until one works
      DioException? lastError;
      GeminiApiException? lastApiException;

      for (final model in _geminiModels) {
        try {
          _log('🔄 Trying model: $model');

          final requestData = {
            'contents': [
              {
                'parts': [
                  {
                    'text':
                        'You are a nutrition expert. Analyze food descriptions and provide accurate calorie estimates. Return ONLY valid JSON. Do NOT include "Here is the JSON" or any other text.\n\n$prompt',
                  },
                ],
              },
            ],
            'generationConfig': {
              'temperature':
                  0.1, // Lower temperature for more deterministic output
              'maxOutputTokens': 1000,
              'responseMimeType': 'application/json',
            },
          };

          final response = await _makeRequestWithRetry(model, requestData);

          _geminiModel = model; // Save working model
          _log('✅ Successfully using model: $model');
          final data = response.data;

          // Try to extract content from response
          String? content;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final candidate = candidates[0] as Map<String, dynamic>?;
            final candidateContent =
                candidate?['content'] as Map<String, dynamic>?;
            final parts = candidateContent?['parts'] as List?;

            if (parts != null && parts.isNotEmpty) {
              // Try to get text from all parts and concatenate
              final textParts = <String>[];
              for (var part in parts) {
                if (part is Map<String, dynamic>) {
                  final text = part['text'] as String?;
                  if (text != null && text.isNotEmpty) {
                    textParts.add(text);
                  }
                }
              }
              if (textParts.isNotEmpty) {
                content = textParts.join('\n');
              }
            }
          }

          if (content != null && content.isNotEmpty) {
            final result = _parseCalorieResponse(content);
            if (result != null) {
              _log('✅ Calories calculated: $result kcal');
              return result;
            }
          } else {
            _log(
              '⚠️ No content found in response. Response structure: ${data.toString().substring(0, data.toString().length > 500 ? 500 : data.toString().length)}',
            );
          }
        } on GeminiApiException catch (e) {
          lastApiException = e;
          // If it's a 503 error, we've already retried, so try next model
          if (e.statusCode == 503) {
            _log('⚠️ Model $model overloaded after retries, trying next...');
            continue;
          }
          // For other API exceptions, rethrow
          rethrow;
        } on DioException catch (e) {
          lastError = e;
          // Handle both Model Not Found (404) and Quota Exceeded (429)
          if (e.response?.statusCode == 404 || e.response?.statusCode == 429) {
            final reason = e.response?.statusCode == 404
                ? 'not available'
                : 'quota exceeded';
            _log('⚠️ Model $model $reason, trying next...');
            continue; // Try next model
          } else if (e.response?.statusCode == 503) {
            // This shouldn't happen since _makeRequestWithRetry handles 503, but just in case
            _log('⚠️ Model $model overloaded, trying next...');
            continue;
          } else {
            rethrow; // Re-throw other errors
          }
        }
      }

      // If we get here, all models failed
      // Try dynamic model discovery as a last resort
      if (lastError != null || lastApiException != null) {
        _log(
          '⚠️ All static models failed. Attempting dynamic model discovery...',
        );
        final dynamicResult = await _tryDynamicModels(
          'food',
          prompt,
          (content) => _parseCalorieResponse(content),
        );

        if (dynamicResult != null) {
          return dynamicResult;
        }

        // Throw user-friendly exception
        if (lastApiException != null) {
          throw lastApiException;
        }

        // Convert DioException to user-friendly message
        if (lastError != null) {
          final statusCode = lastError.response?.statusCode;
          if (statusCode == 429) {
            throw GeminiApiException(
              'API quota exceeded',
              statusCode: 429,
              userMessage: 'AI service quota exceeded. Please try again later.',
            );
          } else if (statusCode == 404) {
            throw GeminiApiException(
              'Model not found',
              statusCode: 404,
              userMessage:
                  'AI service configuration error. Please contact support.',
            );
          } else {
            throw GeminiApiException(
              lastError.message ?? 'Unknown error',
              statusCode: statusCode,
              userMessage:
                  'Unable to analyze food. Please try again or enter calories manually.',
            );
          }
        }
      }

      // This code is now handled in the loop above
      _log(
        '❌ Failed to get valid response from Gemini after trying all models',
      );
      throw GeminiApiException(
        'No available models',
        userMessage:
            'Unable to analyze food at this time. Please enter calories manually.',
      );
    } on GeminiApiException {
      rethrow; // Re-throw user-friendly exceptions as-is
    } on DioException catch (e) {
      _log('❌ Gemini API error: ${e.message}');
      if (e.response != null) {
        _log('Response: ${e.response?.data}');
      }

      // Convert to user-friendly exception
      final statusCode = e.response?.statusCode;
      if (statusCode == 503) {
        throw GeminiApiException(
          'Service overloaded',
          statusCode: 503,
          userMessage:
              'The AI service is temporarily busy. Please wait a moment and try again.',
        );
      } else if (statusCode == 429) {
        throw GeminiApiException(
          'Quota exceeded',
          statusCode: 429,
          userMessage: 'AI service quota exceeded. Please try again later.',
        );
      } else {
        throw GeminiApiException(
          e.message ?? 'Unknown error',
          statusCode: statusCode,
          userMessage:
              'Unable to analyze food. Please try again or enter calories manually.',
        );
      }
    } catch (e) {
      _log('❌ Error analyzing food calories: $e');
      if (e is GeminiApiException) {
        rethrow;
      }
      throw GeminiApiException(
        e.toString(),
        userMessage:
            'Unable to analyze food. Please try again or enter calories manually.',
      );
    }
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

  /// Parse OpenAI response to extract calorie count
  int? _parseCalorieResponse(String jsonContent) {
    try {
      _log(
        '📝 Raw response content (length: ${jsonContent.length}): ${jsonContent.substring(0, jsonContent.length > 200 ? 200 : jsonContent.length)}${jsonContent.length > 200 ? "..." : ""}',
      );

      // Clean up the response - extract JSON from markdown code blocks or text
      String cleanContent = jsonContent.trim();

      // If content is too short or doesn't contain JSON-like characters, it might be incomplete
      if (cleanContent.length < 10 ||
          (!cleanContent.contains('{') && !cleanContent.contains('['))) {
        _log(
          '⚠️ Response appears incomplete or missing JSON. Full content: $cleanContent',
        );
        return null;
      }

      // Remove markdown code blocks (```json or ```)
      if (cleanContent.contains('```json')) {
        // Extract content between ```json and ```
        final startIndex = cleanContent.indexOf('```json') + 7;
        final endIndex = cleanContent.lastIndexOf('```');
        if (endIndex > startIndex) {
          cleanContent = cleanContent.substring(startIndex, endIndex).trim();
        } else {
          cleanContent = cleanContent
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
        }
      } else if (cleanContent.contains('```')) {
        // Extract content between ``` and ```
        final startIndex = cleanContent.indexOf('```') + 3;
        final endIndex = cleanContent.lastIndexOf('```');
        if (endIndex > startIndex) {
          cleanContent = cleanContent.substring(startIndex, endIndex).trim();
        } else {
          cleanContent = cleanContent.replaceAll('```', '').trim();
        }
      }

      // Remove any leading text before JSON (e.g., "Here is the JSON requested:")
      // Find the first occurrence of '{' which should be the start of JSON
      final jsonStartIndex = cleanContent.indexOf('{');
      if (jsonStartIndex > 0) {
        cleanContent = cleanContent.substring(jsonStartIndex);
      }

      // Also check for trailing text after JSON (find last '}')
      final jsonEndIndex = cleanContent.lastIndexOf('}');
      if (jsonEndIndex > 0 && jsonEndIndex < cleanContent.length - 1) {
        cleanContent = cleanContent.substring(0, jsonEndIndex + 1);
      }

      cleanContent = cleanContent.trim();

      // Validate that we have something that looks like JSON
      if (!cleanContent.startsWith('{') || !cleanContent.endsWith('}')) {
        _log(
          '⚠️ Content does not appear to be valid JSON. Attempting to find JSON object...',
        );

        // Try to find JSON object even if there's extra text
        final jsonMatch = RegExp(
          r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}',
        ).firstMatch(cleanContent);
        if (jsonMatch != null) {
          cleanContent = jsonMatch.group(0)!;
          _log('✅ Found JSON object in response');
        } else {
          _log('❌ Could not extract valid JSON from response');
          return null;
        }
      }

      final json = jsonDecode(cleanContent) as Map<String, dynamic>;

      // Try to get calories from the response
      final calories = json['calories'];

      if (calories != null) {
        if (calories is int) {
          return calories;
        } else if (calories is double) {
          return calories.round();
        } else if (calories is String) {
          final parsed = int.tryParse(calories);
          if (parsed != null) return parsed;
        }
      }

      _log(
        '❌ Unable to parse calories from response. JSON keys: ${json.keys.join(", ")}',
      );
      return null;
    } catch (e, stackTrace) {
      _log('❌ Error parsing Gemini response: $e');
      _log('Stack trace: $stackTrace');
      return null;
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
        throw Exception('Gemini service not initialized');
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
      GeminiApiException? lastApiException;

      for (final model in _geminiModels) {
        try {
          _log('🔄 Trying model: $model');

          final requestData = {
            'contents': [
              {
                'parts': [
                  {
                    'text':
                        'You are a fitness and exercise expert. Analyze exercise descriptions and calculate accurate calorie burn estimates based on duration. Return ONLY valid JSON. Do NOT include "Here is the JSON" or any other text.\n\n$prompt',
                  },
                ],
              },
            ],
            'generationConfig': {
              'temperature':
                  0.1, // Lower temperature for more deterministic output
              'maxOutputTokens': 1000,
              'responseMimeType': 'application/json',
            },
          };

          final response = await _makeRequestWithRetry(model, requestData);

          _geminiModel = model; // Save working model
          _log('✅ Successfully using model: $model');
          final data = response.data;

          // Try to extract content from response
          String? content;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final candidate = candidates[0] as Map<String, dynamic>?;
            final candidateContent =
                candidate?['content'] as Map<String, dynamic>?;
            final parts = candidateContent?['parts'] as List?;

            if (parts != null && parts.isNotEmpty) {
              // Try to get text from all parts and concatenate
              final textParts = <String>[];
              for (var part in parts) {
                if (part is Map<String, dynamic>) {
                  final text = part['text'] as String?;
                  if (text != null && text.isNotEmpty) {
                    textParts.add(text);
                  }
                }
              }
              if (textParts.isNotEmpty) {
                content = textParts.join('\n');
              }
            }
          }

          if (content != null && content.isNotEmpty) {
            final result = _parseCalorieResponse(content);
            if (result != null) {
              _log('✅ Calories burned calculated: $result kcal');
              return result;
            }
          } else {
            _log(
              '⚠️ No content found in response. Response structure: ${data.toString().substring(0, data.toString().length > 500 ? 500 : data.toString().length)}',
            );
          }
        } on GeminiApiException catch (e) {
          lastApiException = e;
          // If it's a 503 error, we've already retried, so try next model
          if (e.statusCode == 503) {
            _log('⚠️ Model $model overloaded after retries, trying next...');
            continue;
          }
          // For other API exceptions, rethrow
          rethrow;
        } on DioException catch (e) {
          lastError = e;
          // Handle both Model Not Found (404) and Quota Exceeded (429)
          if (e.response?.statusCode == 404 || e.response?.statusCode == 429) {
            final reason = e.response?.statusCode == 404
                ? 'not available'
                : 'quota exceeded';
            _log('⚠️ Model $model $reason, trying next...');
            continue; // Try next model
          } else if (e.response?.statusCode == 503) {
            // This shouldn't happen since _makeRequestWithRetry handles 503, but just in case
            _log('⚠️ Model $model overloaded, trying next...');
            continue;
          } else {
            rethrow; // Re-throw other errors
          }
        }
      }

      // If we get here, all models failed
      // Try dynamic model discovery as a last resort
      if (lastError != null || lastApiException != null) {
        _log(
          '⚠️ All static models failed. Attempting dynamic model discovery...',
        );
        final dynamicResult = await _tryDynamicModels(
          'exercise',
          prompt,
          (content) => _parseCalorieResponse(content),
        );

        if (dynamicResult != null) {
          return dynamicResult;
        }

        // Throw user-friendly exception
        if (lastApiException != null) {
          throw lastApiException;
        }

        // Convert DioException to user-friendly message
        if (lastError != null) {
          final statusCode = lastError.response?.statusCode;
          if (statusCode == 429) {
            throw GeminiApiException(
              'API quota exceeded',
              statusCode: 429,
              userMessage: 'AI service quota exceeded. Please try again later.',
            );
          } else if (statusCode == 404) {
            throw GeminiApiException(
              'Model not found',
              statusCode: 404,
              userMessage:
                  'AI service configuration error. Please contact support.',
            );
          } else {
            throw GeminiApiException(
              lastError.message ?? 'Unknown error',
              statusCode: statusCode,
              userMessage:
                  'Unable to analyze exercise. Please try again or enter calories manually.',
            );
          }
        }
      }

      _log(
        '❌ Failed to get valid response from Gemini after trying all models',
      );
      throw GeminiApiException(
        'No available models',
        userMessage:
            'Unable to analyze exercise at this time. Please enter calories manually.',
      );
    } on GeminiApiException {
      rethrow; // Re-throw user-friendly exceptions as-is
    } on DioException catch (e) {
      _log('❌ Gemini API error: ${e.message}');
      if (e.response != null) {
        _log('Response: ${e.response?.data}');
      }

      // Convert to user-friendly exception
      final statusCode = e.response?.statusCode;
      if (statusCode == 503) {
        throw GeminiApiException(
          'Service overloaded',
          statusCode: 503,
          userMessage:
              'The AI service is temporarily busy. Please wait a moment and try again.',
        );
      } else if (statusCode == 429) {
        throw GeminiApiException(
          'Quota exceeded',
          statusCode: 429,
          userMessage: 'AI service quota exceeded. Please try again later.',
        );
      } else {
        throw GeminiApiException(
          e.message ?? 'Unknown error',
          statusCode: statusCode,
          userMessage:
              'Unable to analyze exercise. Please try again or enter calories manually.',
        );
      }
    } catch (e) {
      _log('❌ Error analyzing exercise calories: $e');
      if (e is GeminiApiException) {
        rethrow;
      }
      throw GeminiApiException(
        e.toString(),
        userMessage:
            'Unable to analyze exercise. Please try again or enter calories manually.',
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

  /// Try to find and use available models dynamically
  Future<int?> _tryDynamicModels(
    String type,
    String prompt,
    int? Function(String) parser,
  ) async {
    try {
      final models = await listAvailableModels();
      final generateContentModels = models.where((m) {
        final methods =
            (m['supportedGenerationMethods'] as List<dynamic>?) ?? [];
        return methods.contains('generateContent');
      }).toList();

      if (generateContentModels.isEmpty) {
        _log('❌ No models found that support generateContent');
        return null;
      }

      _log(
        '📋 Found ${generateContentModels.length} models supporting generateContent',
      );

      for (var modelData in generateContentModels) {
        // Extract model name (e.g., "models/gemini-pro" -> "gemini-pro")
        String modelName = modelData['name'] as String;
        if (modelName.startsWith('models/')) {
          modelName = modelName.substring(7);
        }

        // Skip if we already tried this model in the static list
        if (_geminiModels.contains(modelName)) {
          continue;
        }

        try {
          _log('🔄 Trying dynamic model: $modelName');

          final systemPrompt = type == 'food'
              ? 'You are a nutrition expert. Analyze food descriptions and provide accurate calorie estimates. Return ONLY valid JSON. Do NOT include "Here is the JSON" or any other text.\n\n$prompt'
              : 'You are a fitness and exercise expert. Analyze exercise descriptions and calculate accurate calorie burn estimates based on duration. Return ONLY valid JSON. Do NOT include "Here is the JSON" or any other text.\n\n$prompt';

          final requestData = {
            'contents': [
              {
                'parts': [
                  {'text': systemPrompt},
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.1,
              'maxOutputTokens': 1000,
              'responseMimeType': 'application/json',
            },
          };

          final response = await _makeRequestWithRetry(modelName, requestData);

          if (response.statusCode == 200) {
            _geminiModel = modelName; // Save working model
            _log('✅ Successfully using dynamic model: $modelName');
            final data = response.data;

            // Try to extract content from response
            String? content;
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final candidate = candidates[0] as Map<String, dynamic>?;
              final candidateContent =
                  candidate?['content'] as Map<String, dynamic>?;
              final parts = candidateContent?['parts'] as List?;

              if (parts != null && parts.isNotEmpty) {
                final textParts = <String>[];
                for (var part in parts) {
                  if (part is Map<String, dynamic>) {
                    final text = part['text'] as String?;
                    if (text != null && text.isNotEmpty) {
                      textParts.add(text);
                    }
                  }
                }
                if (textParts.isNotEmpty) {
                  content = textParts.join('\n');
                }
              }
            }

            if (content != null && content.isNotEmpty) {
              final result = parser(content);
              if (result != null) {
                return result;
              }
            }
          }
        } catch (e) {
          _log('⚠️ Dynamic model $modelName failed: $e');
        }
      }
    } catch (e) {
      _log('❌ Error in dynamic model discovery: $e');
    }

    return null;
  }

  /// List available Gemini models
  /// This helps identify which models are available for your API key
  Future<List<Map<String, dynamic>>> listAvailableModels() async {
    try {
      await _ensureInitialized();
      if (_dio == null) {
        throw Exception('Gemini service not initialized');
      }

      _log('📋 Fetching available models...');

      // Try v1beta first (more models available)
      try {
        final dioV1Beta = Dio(
          BaseOptions(
            baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: {'Content-Type': 'application/json'},
          ),
        );

        final response = await dioV1Beta.get(
          '/models',
          queryParameters: {'key': _apiKey},
        );

        if (response.statusCode == 200) {
          final data = response.data;
          final models = (data['models'] as List<dynamic>?) ?? [];
          _log('✅ Found ${models.length} models in v1beta');

          // Log each model
          for (var model in models) {
            final name = model['name'] ?? 'Unknown';
            final displayName = model['displayName'] ?? '';
            final supportedMethods =
                (model['supportedGenerationMethods'] as List<dynamic>?) ?? [];
            _log(
              '  📌 $name ($displayName) - Methods: ${supportedMethods.join(", ")}',
            );
          }

          return models.map((m) => Map<String, dynamic>.from(m)).toList();
        }
      } catch (e) {
        _log('⚠️ v1beta listModels failed: $e');
      }

      // Try v1 as fallback
      final response = await _dio!.get(
        '/models',
        queryParameters: {'key': _apiKey},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final models = (data['models'] as List<dynamic>?) ?? [];
        _log('✅ Found ${models.length} models in v1');

        // Log each model
        for (var model in models) {
          final name = model['name'] ?? 'Unknown';
          final displayName = model['displayName'] ?? '';
          final supportedMethods =
              (model['supportedGenerationMethods'] as List<dynamic>?) ?? [];
          _log(
            '  📌 $name ($displayName) - Methods: ${supportedMethods.join(", ")}',
          );
        }

        return models.map((m) => Map<String, dynamic>.from(m)).toList();
      }

      _log('❌ Failed to get models list');
      return [];
    } on DioException catch (e) {
      _log('❌ Error listing models: ${e.message}');
      if (e.response != null) {
        _log('Response: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      _log('❌ Error listing models: $e');
      rethrow;
    }
  }
}

class GeminiException implements Exception {
  final String message;
  final int? statusCode;

  GeminiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'GeminiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
