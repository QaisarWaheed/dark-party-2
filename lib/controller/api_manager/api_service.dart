// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
import 'package:shaheen_star_app/utils/auth_event_bus.dart';

/// Centralized API Service with Best Practices
///
/// Features:
/// - Consistent error handling
/// - Retry logic for failed requests
/// - Timeout handling
/// - Response parsing utilities
/// - Logging and debugging
class ApiService {
  // ==================== Configuration ====================

  /// Default timeout for API requests (30 seconds)
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Maximum retry attempts for failed requests
  static const int maxRetries = 3;

  /// Retry delay between attempts
  static const Duration retryDelay = Duration(seconds: 2);

  // ==================== Common Headers ====================

  /// Get common headers for API requests
  static Map<String, String> getCommonHeaders({
    bool includeAuth = true,
    String? contentType,
    Map<String, String>? additionalHeaders,
  }) {
    final headers = <String, String>{
      if (includeAuth) 'Authorization': 'Bearer ${ApiConstants.bearertoken}',
      if (contentType != null) 'Content-Type': contentType,
      'Accept': 'application/json',
    };

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  // ==================== HTTP Methods with Retry Logic ====================

  /// Execute GET request with retry logic
  static Future<ApiResponse<T>> get<T>({
    required String url,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
    int? maxRetries,
    T Function(Map<String, dynamic>)? parser,
  }) async {
    return _executeWithRetry(
      request: () => _getRequest(url, headers, queryParameters, timeout),
      maxRetries: maxRetries,
      parser: parser,
    );
  }

  /// Execute POST request with retry logic
  static Future<ApiResponse<T>> post<T>({
    required String url,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Duration? timeout,
    int? maxRetries,
    T Function(Map<String, dynamic>)? parser,
  }) async {
    return _executeWithRetry(
      request: () => _postRequest(url, headers, body, timeout),
      maxRetries: maxRetries,
      parser: parser,
    );
  }

  /// Execute Multipart POST request with retry logic
  static Future<ApiResponse<T>> postMultipart<T>({
    required String url,
    Map<String, String>? headers,
    Map<String, String>? fields,
    Map<String, http.MultipartFile>? files,
    Duration? timeout,
    int? maxRetries,
    T Function(Map<String, dynamic>)? parser,
  }) async {
    return _executeWithRetry(
      request: () =>
          _postMultipartRequest(url, headers, fields, files, timeout),
      maxRetries: maxRetries,
      parser: parser,
    );
  }

  // ==================== Private HTTP Methods ====================

  static Future<http.Response> _getRequest(
    String url,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  ) async {
    var uri = Uri.parse(url);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(
        queryParameters: queryParameters.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
    }

    print('📤 [ApiService] GET Request: $uri');
    if (headers != null) print('   Headers: $headers');

    final response = await http
        .get(uri, headers: headers)
        .timeout(timeout ?? defaultTimeout);

    print('📥 [ApiService] GET Response: ${response.statusCode}');
    return response;
  }

  static Future<http.Response> _postRequest(
    String url,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Duration? timeout,
  ) async {
    final uri = Uri.parse(url);

    print('📤 [ApiService] POST Request: $uri');
    if (headers != null) print('   Headers: $headers');
    if (body != null) print('   Body: $body');

    final response = await http
        .post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout ?? defaultTimeout);

    print('📥 [ApiService] POST Response: ${response.statusCode}');
    return response;
  }

  static Future<http.StreamedResponse> _postMultipartRequest(
    String url,
    Map<String, String>? headers,
    Map<String, String>? fields,
    Map<String, http.MultipartFile>? files,
    Duration? timeout,
  ) async {
    final uri = Uri.parse(url);
    final request = http.MultipartRequest('POST', uri);

    if (headers != null) {
      request.headers.addAll(headers);
    }
    if (fields != null) {
      request.fields.addAll(fields);
    }
    if (files != null) {
      request.files.addAll(files.values);
    }

    print('📤 [ApiService] POST Multipart Request: $uri');
    if (headers != null) print('   Headers: $headers');
    if (fields != null) print('   Fields: $fields');

    final response = await request.send().timeout(timeout ?? defaultTimeout);

    print('📥 [ApiService] POST Multipart Response: ${response.statusCode}');
    return response;
  }

  // ==================== Retry Logic ====================

  static Future<ApiResponse<T>> _executeWithRetry<T>({
    required Future<dynamic> Function() request,
    int? maxRetries,
    T Function(Map<String, dynamic>)? parser,
  }) async {
    int attempts = 0;
    final maxAttempts = maxRetries ?? ApiService.maxRetries;

    while (attempts < maxAttempts) {
      try {
        attempts++;
        print('🔄 [ApiService] Attempt $attempts/$maxAttempts');

        final response = await request();

        // Handle StreamedResponse (from MultipartRequest)
        if (response is http.StreamedResponse) {
          final statusCode = response.statusCode;
          final responseBody = await response.stream.bytesToString();

          if (_looksLikeAuthInvalid(statusCode, responseBody)) {
            AuthEventBus().reportInvalidToken(
              _extractAuthMessage(responseBody),
            );
            return ApiResponse.error(
              'Authentication invalid',
              statusCode: statusCode,
            );
          }

          if (statusCode == 200) {
            final parsed = _parseResponse(responseBody, parser);
            return parsed;
          } else {
            if (attempts < maxAttempts) {
              print(
                '⚠️ [ApiService] Retrying after ${retryDelay.inSeconds}s...',
              );
              await Future.delayed(retryDelay);
              continue;
            }
            return ApiResponse.error(
              'HTTP Error: $statusCode',
              statusCode: statusCode,
            );
          }
        }

        // Handle regular Response
        if (response is http.Response) {
          if (_looksLikeAuthInvalid(response.statusCode, response.body)) {
            AuthEventBus().reportInvalidToken(
              _extractAuthMessage(response.body),
            );
            return ApiResponse.error(
              'Authentication invalid',
              statusCode: response.statusCode,
            );
          }

          if (response.statusCode == 200) {
            final parsed = _parseResponse(response.body, parser);
            return parsed;
          } else {
            if (attempts < maxAttempts) {
              print(
                '⚠️ [ApiService] Retrying after ${retryDelay.inSeconds}s...',
              );
              await Future.delayed(retryDelay);
              continue;
            }
            return ApiResponse.error(
              'HTTP Error: ${response.statusCode}',
              statusCode: response.statusCode,
            );
          }
        }

        return ApiResponse.error('Unknown response type');
      } on TimeoutException {
        if (attempts < maxAttempts) {
          print('⏱️ [ApiService] Timeout, retrying...');
          await Future.delayed(retryDelay);
          continue;
        }
        return ApiResponse.error('Request timeout');
      } catch (e, stackTrace) {
        if (attempts < maxAttempts) {
          print('❌ [ApiService] Error: $e, retrying...');
          await Future.delayed(retryDelay);
          continue;
        }
        print('❌ [ApiService] Final error: $e');
        print('   Stack trace: $stackTrace');
        return ApiResponse.error('Network error: $e');
      }
    }

    return ApiResponse.error('Max retries exceeded');
  }

  static bool _looksLikeAuthInvalid(int statusCode, String body) {
    if (statusCode == 401 || statusCode == 403) return true;
    final lowered = body.toLowerCase();
    return lowered.contains('invalid token') ||
        lowered.contains('token expired') ||
        lowered.contains('unauthorized') ||
        lowered.contains('authentication failed') ||
        lowered.contains('auth failed');
  }

  static String? _extractAuthMessage(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map) {
        final message =
            decoded['message'] ?? decoded['error'] ?? decoded['msg'];
        return message?.toString();
      }
    } catch (_) {
      // Ignore parse errors and fall back to null.
    }
    return null;
  }

  // ==================== Response Parsing ====================

  static ApiResponse<T> _parseResponse<T>(
    String responseBody,
    T Function(Map<String, dynamic>)? parser,
  ) {
    try {
      // Clean response (remove HTML comments, etc.)
      final cleanedBody = _cleanResponse(responseBody);

      // Parse JSON
      final jsonData = json.decode(cleanedBody) as Map<String, dynamic>;

      // Check API status
      final status = jsonData['status']?.toString().toLowerCase();
      if (status == 'error' || status == 'failed') {
        final message = jsonData['message']?.toString() ?? 'Unknown error';
        return ApiResponse.error(message, data: jsonData);
      }

      // Parse with custom parser if provided
      if (parser != null) {
        try {
          final parsed = parser(jsonData);
          return ApiResponse.success(parsed, rawData: jsonData);
        } catch (e) {
          print('⚠️ [ApiService] Parser error: $e');
          return ApiResponse.success(null as T, rawData: jsonData);
        }
      }

      // Return raw data
      return ApiResponse.success(jsonData as T, rawData: jsonData);
    } catch (e, stackTrace) {
      print('❌ [ApiService] Parse error: $e');
      print(
        '   Response body: ${responseBody.substring(0, responseBody.length > 500 ? 500 : responseBody.length)}',
      );
      print('   Stack trace: $stackTrace');
      return ApiResponse.error('Failed to parse response: $e');
    }
  }

  /// Clean response body (remove HTML comments, extract JSON, etc.)
  static String _cleanResponse(String responseBody) {
    String cleaned = responseBody.trim();

    // Remove HTML comments
    if (cleaned.contains('<!--')) {
      cleaned = cleaned.substring(0, cleaned.indexOf('<!--')).trim();
    }

    // Extract JSON if mixed with HTML
    if (cleaned.contains('<!')) {
      final jsonStart = cleaned.indexOf('{');
      if (jsonStart != -1) {
        cleaned = cleaned.substring(jsonStart);
      }
    }

    // Extract complete JSON object
    if (cleaned.startsWith('{')) {
      int braceCount = 0;
      int startIndex = cleaned.indexOf('{');
      int endIndex = -1;

      for (int i = startIndex; i < cleaned.length; i++) {
        if (cleaned[i] == '{') {
          braceCount++;
        } else if (cleaned[i] == '}') {
          braceCount--;
          if (braceCount == 0) {
            endIndex = i + 1;
            break;
          }
        }
      }

      if (endIndex != -1) {
        cleaned = cleaned.substring(startIndex, endIndex);
      }
    }

    return cleaned;
  }
}

// ==================== API Response Model ====================

/// Generic API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? rawData;

  ApiResponse._({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
    this.rawData,
  });

  factory ApiResponse.success(T data, {Map<String, dynamic>? rawData}) {
    return ApiResponse._(success: true, data: data, rawData: rawData);
  }

  factory ApiResponse.error(
    String error, {
    int? statusCode,
    Map<String, dynamic>? data,
  }) {
    return ApiResponse._(
      success: false,
      error: error,
      statusCode: statusCode,
      rawData: data,
    );
  }

  /// Check if response is successful
  bool get isSuccess => success;

  /// Get error message or null
  String? get errorMessage => error;

  /// Get data or throw if error
  T get requireData {
    if (!success || data == null) {
      throw Exception(error ?? 'No data available');
    }
    return data!;
  }
}
