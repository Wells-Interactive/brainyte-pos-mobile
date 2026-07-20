import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'api_response.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  final CookieJar _cookieJar = CookieJar();

  Future<void> initialize() async {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.requestTimeout,
        receiveTimeout: AppConstants.requestTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  Future<void> clearSessionCookies() async {
    await _cookieJar.deleteAll();
  }

  Future<ApiResponse<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.post(path, data: body ?? {});
      return ApiResponse.success(
        response.data is Map<String, dynamic> ? response.data : {'message': response.data},
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      return ApiResponse.failure(_extractMessage(error), statusCode: error.response?.statusCode);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return ApiResponse.success(
        response.data is Map<String, dynamic> ? response.data : {'message': response.data},
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      return ApiResponse.failure(_extractMessage(error), statusCode: error.response?.statusCode);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.put(path, data: body ?? {});
      return ApiResponse.success(
        response.data is Map<String, dynamic> ? response.data : {'message': response.data},
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      return ApiResponse.failure(_extractMessage(error), statusCode: error.response?.statusCode);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return ApiResponse.success(
        response.data is Map<String, dynamic> ? response.data : {'message': response.data},
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      return ApiResponse.failure(_extractMessage(error), statusCode: error.response?.statusCode);
    }
  }

  Future<void> clearSession() async {
    await clearSessionCookies();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.roleKey);
    await prefs.remove(AppConstants.authTokenKey);
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  String _extractMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      return data['error']?.toString() ?? 'Request failed';
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return decoded['error']?.toString() ?? 'Request failed';
        }
      } catch (_) {
        return data;
      }
    }
    return error.message ?? 'Request failed';
  }
}
