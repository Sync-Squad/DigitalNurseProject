import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'token_service.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();

  // Chat with AI Assistant
  Future<Map<String, dynamic>> chat({
    required String message,
    int? conversationId,
    int? elderUserId,
  }) async {
    try {
      final response = await _apiService.post(
        '/ai/chat',
        data: {
          'message': message,
          if (conversationId != null) 'conversationId': conversationId,
          if (elderUserId != null) 'elderUserId': elderUserId,
        },
      );
      // Convert conversationId from string to int if present
      final data = response.data as Map<String, dynamic>;
      if (data['conversationId'] != null) {
        data['conversationId'] =
            int.tryParse(data['conversationId'].toString()) ??
            data['conversationId'];
      }
      return data;
    } catch (e) {
      throw Exception('Failed to send chat message: $e');
    }
  }

  // Get conversations
  Future<List<dynamic>> getConversations({int? elderUserId}) async {
    try {
      final response = await _apiService.get(
        '/ai/conversations',
        queryParameters: elderUserId != null
            ? {'elderUserId': elderUserId}
            : null,
      );
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to get conversations: $e');
    }
  }

  // Get conversation history
  Future<Map<String, dynamic>> getConversation(int conversationId) async {
    try {
      final response = await _apiService.get(
        '/ai/conversations/$conversationId',
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to get conversation: $e');
    }
  }

  // Get AI insights
  Future<List<dynamic>> getInsights({
    List<String>? types,
    List<String>? priorities,
    List<String>? categories,
    bool? isRead,
    int? elderUserId,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (types != null && types.isNotEmpty) {
        queryParams['types'] = types;
      }
      if (priorities != null && priorities.isNotEmpty) {
        queryParams['priorities'] = priorities;
      }
      if (categories != null && categories.isNotEmpty) {
        queryParams['categories'] = categories;
      }
      if (isRead != null) {
        queryParams['isRead'] = isRead;
      }
      if (elderUserId != null) {
        queryParams['elderUserId'] = elderUserId;
      }

      final response = await _apiService.get(
        '/ai/insights',
        queryParameters: queryParams,
      );
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to get insights: $e');
    }
  }

  // Generate insight
  Future<Map<String, dynamic>> generateInsight({
    required String insightType,
    required int elderUserId,
    String? priority,
    String? category,
  }) async {
    try {
      final response = await _apiService.post(
        '/ai/insights/generate',
        data: {
          'insightType': insightType,
          'elderUserId': elderUserId,
          if (priority != null) 'priority': priority,
          if (category != null) 'category': category,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to generate insight: $e');
    }
  }

  // Mark insight as read
  Future<void> markInsightAsRead(int insightId) async {
    try {
      await _apiService.put('/ai/insights/$insightId/read');
    } catch (e) {
      throw Exception('Failed to mark insight as read: $e');
    }
  }

  // Archive insight
  Future<void> archiveInsight(int insightId) async {
    try {
      await _apiService.put('/ai/insights/$insightId/archive');
    } catch (e) {
      throw Exception('Failed to archive insight: $e');
    }
  }

  // Generate insights for user
  Future<Map<String, dynamic>> generateInsightsForUser({
    required int elderUserId,
  }) async {
    try {
      final response = await _apiService.post(
        '/ai/insights/generate-for-user',
        data: {'elderUserId': elderUserId},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to generate insights: $e');
    }
  }

  // Analyze health
  Future<Map<String, dynamic>> analyzeHealth({
    int? elderUserId,
    String? startDate,
    String? endDate,
    List<String>? analysisTypes,
  }) async {
    try {
      final response = await _apiService.post(
        '/ai/analyze',
        data: {
          if (elderUserId != null) 'elderUserId': elderUserId,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          if (analysisTypes != null) 'analysisTypes': analysisTypes,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to analyze health: $e');
    }
  }

  // Semantic search
  Future<List<dynamic>> semanticSearch({
    required String query,
    String? entityType,
    double? threshold,
    int? limit,
    int? elderUserId,
  }) async {
    try {
      final response = await _apiService.post(
        '/ai/search',
        data: {
          'query': query,
          if (entityType != null) 'entityType': entityType,
          if (threshold != null) 'threshold': threshold,
          if (limit != null) 'limit': limit,
          if (elderUserId != null) 'elderUserId': elderUserId,
        },
      );
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to perform semantic search: $e');
    }
  }

  // Process document for Q&A
  Future<void> processDocument(int documentId, String text) async {
    try {
      await _apiService.post(
        '/ai/documents/$documentId/process',
        data: {'text': text},
      );
    } catch (e) {
      throw Exception('Failed to process document: $e');
    }
  }

  // Ask question about document
  Future<Map<String, dynamic>> askDocument({
    required int documentId,
    required String question,
  }) async {
    try {
      final response = await _apiService.post(
        '/ai/documents/$documentId/ask',
        data: {'question': question},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to ask document: $e');
    }
  }
}
