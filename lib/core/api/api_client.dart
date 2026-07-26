import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'api_response.dart';
import 'endpoints.dart';

/// Singleton API client for communicating with the Brainyte POS backend.
///
/// Features:
/// - Bearer token authentication (v1 API)
/// - Automatic token refresh on 401
/// - v1 response format parsing ({success, data, error, meta})
/// - Legacy endpoint support
/// - Secure token storage via FlutterSecureStorage
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Cached auth token
  String? _accessToken;
  String? _refreshToken;

  // Flag to prevent recursive refresh attempts
  bool _isRefreshing = false;

  /// Initialize the API client.
  /// Must be called once before any API calls (e.g., in main()).
  Future<void> initialize() async {
    // Load stored tokens
    _accessToken = await _secureStorage.read(key: AppConstants.authTokenKey);
    _refreshToken = await _secureStorage.read(key: AppConstants.refreshTokenKey);

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.requestTimeout,
        receiveTimeout: AppConstants.requestTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add auth interceptor for Bearer tokens
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Attach Bearer token if available
        if (_accessToken != null && _accessToken!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Auto-refresh on 401 Unauthorized
        if (error.response?.statusCode == 401 && _refreshToken != null && !_isRefreshing) {
          final refreshed = await _attemptTokenRefresh();
          if (refreshed) {
            // Retry the original request with new token
            final retryOptions = error.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $_accessToken';
            try {
              final retryResponse = await _dio.fetch(retryOptions);
              handler.resolve(retryResponse);
              return;
            } catch (_) {}
          }
        }
        handler.next(error);
      },
    ));
  }

  /// Attempt to refresh the access token using the stored refresh token.
  /// Returns true if successful, false otherwise.
  Future<bool> _attemptTokenRefresh() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    if (_isRefreshing) return false;

    _isRefreshing = true;
    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: AppConstants.requestTimeout,
          receiveTimeout: AppConstants.requestTimeout,
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        ),
      ).post(
        Endpoints.v1RefreshToken,
        data: {'refresh_token': _refreshToken, 'device_name': 'flutter'},
      );

      final body = response.data as Map<String, dynamic>?;
      if (body != null && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          final newAccess = data['access_token']?.toString();
          final newRefresh = data['refresh_token']?.toString();
          if (newAccess != null && newRefresh != null) {
            await _storeTokens(newAccess, newRefresh);
            return true;
          }
        }
      }

      // Refresh failed, clear auth
      await clearSession();
      return false;
    } catch (_) {
      await clearSession();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Store tokens securely and in memory.
  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _secureStorage.write(key: AppConstants.authTokenKey, value: accessToken);
    await _secureStorage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  // ============================================================
  // Public API Methods
  // ============================================================

  /// Get the current access token.
  String? get accessToken => _accessToken;

  /// Get the current refresh token.
  String? get refreshToken => _refreshToken;

  /// Check if user is authenticated (has a valid access token).
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

/// Parse v1 API response from raw response data.
  ///
  /// v1 format: `{ success: bool, data: T?, error: String?, meta: ... }`
  /// Legacy format: `{ success: true, key: value, ... }`
  ApiResponse<T> _parseResponse<T>(
    dynamic responseData,
    int statusCode, {
    required T Function(Map<String, dynamic>) onData,
  }) {
    if (responseData is! Map<String, dynamic>) {
      return ApiResponse.failure('Invalid response format', statusCode: statusCode);
    }

    // v1 format: { "success": true, "data": {...} }
    final success = responseData['success'] == true;
    if (success) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) {
        return ApiResponse.success(onData(data), statusCode: statusCode);
      }
      // If response has no "data" key but has other keys (legacy),
      // pass the whole response as data
      final hasDataKey = responseData.containsKey('data');
      if (!hasDataKey && responseData.keys.any((k) => k != 'success' && k != 'error' && k != 'meta')) {
        return ApiResponse.success(onData(responseData), statusCode: statusCode);
      }
      // "data" exists but is not a Map (e.g., null or list)
      return ApiResponse.success(onData(<String, dynamic>{}), statusCode: statusCode);
    }

    // Error case
    final error = responseData['error']?.toString() ?? 'Request failed';
    return ApiResponse.failure(error, statusCode: statusCode);
  }

  /// Extract error message from DioException.
  String _extractMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      // v1 format: { error: "message" }
      final v1Error = data['error']?.toString();
      if (v1Error != null && v1Error.isNotEmpty) return v1Error;
      // Legacy format
      return data['message']?.toString() ?? 'Request failed';
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return decoded['error']?.toString() ?? decoded['message']?.toString() ?? data;
        }
      } catch (_) {
        return data;
      }
    }
    return error.message ?? 'Request failed';
  }

  // ============================================================
  // HTTP Methods
  // ============================================================

  /// Send a POST request and parse v1 response.
  ///
  /// [onData] converts the response data map to the desired type.
  /// If [onData] is null, returns the raw Map<String, dynamic>.
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? onData,
  }) async {
    try {
      final response = await _dio.post(path, data: body ?? {});
      return _parseResponse<T>(
        response.data,
        response.statusCode ?? 200,
        onData: onData ?? ((data) => data as T),
      );
    } on DioException catch (error) {
      return ApiResponse.failure(_extractMessage(error), statusCode: error.response?.statusCode);
    }
  }

  /// Send a GET request and parse v1 response.
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? onData,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _parseResponse<T>(
        response.data,
        response.statusCode ?? 200,
        onData: onData ?? ((data) => data as T),
      );
    } on DioException catch (error) {
      return ApiResponse.failure(_extractMessage(error), statusCode: error.response?.statusCode);
    }
  }

  /// Send a PUT request and parse v1 response.
  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? onData,
  }) async {
    try {
      final response = await _dio.put(path, data: body ?? {});
      return _parseResponse<T>(
        response.data,
        response.statusCode ?? 200,
        onData: onData ?? ((data) => data as T),
      );
    } on DioException catch (error) {
      return ApiResponse.failure(_extractMessage(error), statusCode: error.response?.statusCode);
    }
  }

  /// Send a DELETE request and parse v1 response.
  Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(Map<String, dynamic>)? onData,
  }) async {
    try {
      final response = await _dio.delete(path);
      return _parseResponse<T>(
        response.data,
        response.statusCode ?? 200,
        onData: onData ?? ((data) => data as T),
      );
    } on DioException catch (error) {
      return ApiResponse.failure(_extractMessage(error), statusCode: error.response?.statusCode);
    }
  }

  /// Legacy: Send a POST request returning raw Map response (for old endpoints).
  Future<ApiResponse<Map<String, dynamic>>> postLegacy(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.post(path, data: body ?? {});
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{'message': response.data};
      return ApiResponse.success(data, statusCode: response.statusCode);
    } on DioException catch (error) {
      return ApiResponse.failure(_extractMessage(error), statusCode: error.response?.statusCode);
    }
  }

  /// Legacy: Send a GET request returning raw Map response (for old endpoints).
  Future<ApiResponse<Map<String, dynamic>>> getLegacy(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{'message': response.data};
      return ApiResponse.success(data, statusCode: response.statusCode);
    } on DioException catch (error) {
      return ApiResponse.failure(_extractMessage(error), statusCode: error.response?.statusCode);
    }
  }

  // ============================================================
  // Session Management
  // ============================================================

  /// Clear all authentication data (tokens, session, stored preferences).
  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.roleKey);
    await prefs.remove(AppConstants.authTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  /// Store auth data after successful login.
  Future<void> storeAuthData({
    required String accessToken,
    required String refreshToken,
    required String role,
    String userId = '',
    String userName = '',
  }) async {
    await _storeTokens(accessToken, refreshToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.roleKey, role);
    if (userId.isNotEmpty) await prefs.setString('user_id', userId);
    if (userName.isNotEmpty) await prefs.setString('user_name', userName);
  }
}
