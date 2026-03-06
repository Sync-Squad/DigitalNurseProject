import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'token_service.dart';

class ApiService {
  static ApiService? _instance;
  Dio? _dio;
  final TokenService _tokenService = TokenService();
  bool _isRefreshing = false;
  bool _isInitializing = false;
  Completer<void>? _initCompleter;
  final List<({RequestOptions options, Completer<Response> completer})> _pendingRequests = [];

  // Singleton pattern
  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  ApiService._internal() {
    // Don't initialize in constructor - let it be lazy
  }

  Future<void> _initialize() async {
    // If already initialized, return immediately
    if (_dio != null) {
      _log('⚠️ [API] Already initialized, skipping');
      return;
    }

    // If already initializing, wait for that to complete
    if (_isInitializing && _initCompleter != null) {
      _log('⏳ [API] Already initializing, waiting...');
      return _initCompleter!.future;
    }

    // Start initialization
    _isInitializing = true;
    _initCompleter = Completer<void>();

    try {
      _log('🚀 [API] Starting initialization...');
      final baseUrl = await AppConfig.getBaseUrl();
      _log('📍 [API] Resolved Base URL: $baseUrl');
      
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          // Improved timeouts: 30s is enough for most connections
          // even with slow email sending on registration.
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 45),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // Verify the base URL was set correctly
      _log('✅ [API] Dio instance created with baseUrl: ${_dio!.options.baseUrl}');
      
      _setupInterceptors();
      _log('✅ [API] API Service fully initialized');
      _initCompleter!.complete();
    } catch (e) {
      _log('❌ [API] Initialization failed: $e');
      _initCompleter!.completeError(e);
      _isInitializing = false;
      _initCompleter = null;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _ensureInitialized() async {
    if (_dio == null) {
      await _initialize();
    }
  }

  Dio get dio {
    if (_dio == null) {
      throw StateError('API Service not initialized. Call _ensureInitialized() first.');
    }
    return _dio!;
  }

  // Update API base URL and reinitialize
  Future<void> updateBaseUrl(String newUrl) async {
    _log('🔄 [API] Updating base URL to: $newUrl');
    await AppConfig.setApiBaseUrl(newUrl);
    _dio = null;
    _isInitializing = false;
    _initCompleter = null;
    await _initialize();
    _log('✅ [API] Base URL updated successfully');
  }

  void _setupInterceptors() {
    // Request interceptor - Add auth token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          _logRequest(options);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response);
          return handler.next(response);
        },
        onError: (error, handler) async {
          _logError(error);
          // Handle 401 Unauthorized - Token expired
          if (error.response?.statusCode == 401) {
            _log('🔄 [API] Token expired, attempting refresh...');
            return _handleTokenRefresh(error, handler);
          }
          return handler.next(error);
        },
      ),
    );
  }

  void _logRequest(RequestOptions options) {
    // Skip logging for medication intakes endpoint
    if (options.path.contains('/medications/') && options.path.endsWith('/intakes')) {
      return;
    }
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 [API REQUEST]');
    print('   Method: ${options.method}');
    print('   Full URL: ${options.uri}');
    print('   Base URL: ${options.baseUrl}');
    print('   Path: ${options.path}');
    if (options.queryParameters.isNotEmpty) {
      print('   Query: ${options.queryParameters}');
    }
    if (options.data != null) {
      print('   Body: ${options.data}');
    }
    print('   Headers: ${options.headers}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  void _logResponse(Response response) {
    // Skip logging for medication intakes endpoint
    if (response.requestOptions.path.contains('/medications/') && 
        response.requestOptions.path.endsWith('/intakes')) {
      return;
    }
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📥 [API RESPONSE]');
    print('   Status: ${response.statusCode} ${response.statusMessage}');
    print('   URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}');
    if (response.data != null) {
      // Truncate large responses for readability
      final dataStr = response.data.toString();
      if (dataStr.length > 500) {
        print('   Data: ${dataStr.substring(0, 500)}... (truncated)');
      } else {
        print('   Data: $dataStr');
      }
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  void _logError(DioException error) {
    // Skip logging for medication intakes endpoint
    if (error.requestOptions.path.contains('/medications/') && 
        error.requestOptions.path.endsWith('/intakes')) {
      return;
    }
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('❌ [API ERROR]');
    print('   Type: ${error.type}');
    print('   URL: ${error.requestOptions.baseUrl}${error.requestOptions.path}');
    if (error.response != null) {
      print('   Status: ${error.response!.statusCode}');
      print('   Message: ${error.response!.data}');
    } else {
      print('   Message: ${error.message}');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  void _log(String message) {
    print('🔍 [API] $message');
  }

  Future<void> _handleTokenRefresh(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    // Prevent multiple simultaneous refresh attempts
    if (_isRefreshing) {
      _log('⏳ [API] Already refreshing, queuing request: ${error.requestOptions.path}');
      // Queue this request to retry after refresh
      final completer = Completer<Response>();
      _pendingRequests.add((options: error.requestOptions, completer: completer));
      
      try {
        final response = await completer.future;
        return handler.resolve(response);
      } catch (e) {
        return handler.reject(e is DioException ? e : error);
      }
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) {
        _log('❌ [API] No refresh token available, clearing tokens and aborting');
        await _tokenService.clearTokens();
        _isRefreshing = false;
        _resolvePendingRequests(error, isError: true);
        return handler.reject(error);
      }

      _log('🔄 [API] Attempting token refresh...');
      // Attempt to refresh token
      final response = await dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newAccessToken = data['accessToken'];
        final newRefreshToken = data['refreshToken'];
        
        await _tokenService.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
        _log('✅ [API] Token refresh successful');

        // Retry original request with new token
        final opts = error.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';
        _log('🔄 [API] Retrying original request: ${opts.method} ${opts.path}');
        
        _isRefreshing = false;
        // Resolve all pending requests FIRST before retrying original to avoid blocking
        _resolvePendingRequests(null, accessToken: newAccessToken);
        
        final retryResponse = await dio.fetch(opts);
        return handler.resolve(retryResponse);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (e) {
      // Refresh failed - clear tokens
      _log('❌ [API] Token refresh failed: $e');
      await _tokenService.clearTokens();
      _isRefreshing = false;
      _resolvePendingRequests(error, isError: true);
      return handler.reject(error);
    } finally {
      _isRefreshing = false;
    }
  }

  void _resolvePendingRequests(DioException? error, {String? accessToken, bool isError = false}) {
    if (_pendingRequests.isEmpty) return;
    
    _log('🔄 [API] Resolving ${_pendingRequests.length} pending requests (Error: $isError)');
    
    for (final pending in _pendingRequests) {
      if (isError) {
        pending.completer.completeError(error ?? Exception('Token refresh failed'));
      } else if (accessToken != null) {
        pending.options.headers['Authorization'] = 'Bearer $accessToken';
        dio.fetch(pending.options).then(
          (resp) => pending.completer.complete(resp),
          onError: (err) => pending.completer.completeError(err),
        );
      }
    }
    _pendingRequests.clear();
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _ensureInitialized();
    try {
      return await dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _ensureInitialized();
    try {
      return await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _ensureInitialized();
    try {
      return await dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _ensureInitialized();
    try {
      return await dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _ensureInitialized();
    try {
      return await dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handler
  Exception _handleError(DioException error) {
    if (error.response != null) {
      // Server responded with error
      final statusCode = error.response!.statusCode;
      final responseData = error.response!.data;
      final message = responseData is Map
          ? (responseData['message'] ?? responseData['error'] ?? 'An error occurred')
          : (responseData?.toString() ?? 'An error occurred');

      _log('❌ [API] Server error response:');
      _log('   Status Code: $statusCode');
      _log('   Response Data: $responseData');
      _log('   Message: $message');

      switch (statusCode) {
        case 400:
          return Exception('Bad request: $message');
        case 401:
          // Use the actual error message from the API response
          return Exception('Unauthorized: $message');
        case 403:
          return Exception('Forbidden: $message');
        case 404:
          return Exception('Not found: $message');
        case 409:
          return Exception('Conflict: $message');
        case 500:
          // Include the actual error message from server if available
          final serverMessage = message != 'An error occurred' ? message : 'Please try again later';
          return Exception('Server error: $serverMessage');
        default:
          return Exception(message);
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timeout: Please check your internet connection');
    } else if (error.type == DioExceptionType.connectionError) {
      // Connection refused - most common issue
      final baseUrl = dio.options.baseUrl;
      String helpfulMessage = 'Connection refused: Cannot reach server at $baseUrl\n\n';
      
      if (baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1')) {
        helpfulMessage += '⚠️ TROUBLESHOOTING:\n';
        helpfulMessage += '1. Make sure your backend server is running\n';
        helpfulMessage += '2. If using a physical device, use your computer\'s IP address instead of localhost\n';
        helpfulMessage += '   Example: http://192.168.1.100:3000/api\n';
        helpfulMessage += '3. Ensure both devices are on the same network\n';
        helpfulMessage += '4. Check firewall settings on your computer\n';
      } else if (baseUrl.contains('10.0.2.2')) {
        helpfulMessage += '⚠️ TROUBLESHOOTING:\n';
        helpfulMessage += '1. Make sure your backend server is running on your host machine\n';
        helpfulMessage += '2. If using Android emulator, 10.0.2.2 should work\n';
        helpfulMessage += '3. If using physical device, set API URL to your computer\'s IP address\n';
      } else {
        helpfulMessage += '⚠️ TROUBLESHOOTING:\n';
        helpfulMessage += '1. Verify the server is running and accessible\n';
        helpfulMessage += '2. Check the API URL is correct: $baseUrl\n';
        helpfulMessage += '3. Ensure both devices are on the same network\n';
      }
      
      _log('❌ Connection Error Details:');
      _log('   URL: $baseUrl');
      _log('   Error: ${error.message}');
      _log('   Socket Error: ${error.error}');
      
      return Exception(helpfulMessage);
    } else {
      return Exception('Network error: ${error.message}');
    }
  }
}

