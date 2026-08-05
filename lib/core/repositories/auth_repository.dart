import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<ApiResponse<UserModel>> login({
    required String email,
    required String password,
    bool requestToken = true,
    String deviceName = 'flutter',
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'request_token': requestToken,
    };
    if (deviceName.isNotEmpty) {
      body['device_name'] = deviceName;
    }

    // Use v1 auth endpoint which returns Bearer tokens
    final result = await _client.post<Map<String, dynamic>>(
      Endpoints.v1Login,
      body: body,
      onData: (data) => data,
    );

    if (!result.success || result.data == null) {
      return ApiResponse.failure(result.error ?? 'Login failed', statusCode: result.statusCode);
    }

    final userData = result.data!['user'] as Map<String, dynamic>?;
    if (userData == null) {
      return ApiResponse.failure('Invalid response from server', statusCode: result.statusCode);
    }

    final role = (userData['role']?.toString() ?? 'waiter').toLowerCase();
    final userId = (userData['id'] as num?)?.toInt().toString() ?? '';
    final userName = userData['name']?.toString() ?? '';

    // Store access token and refresh token via ApiClient's secure storage
    final accessToken = result.data!['access_token']?.toString() ?? '';
    final refreshToken = result.data!['refresh_token']?.toString() ?? '';

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      return ApiResponse.failure(
        'Missing authentication tokens from server',
        statusCode: result.statusCode,
      );
    }

    await _client.storeAuthData(
      accessToken: accessToken,
      refreshToken: refreshToken,
      role: role,
      userId: userId,
      userName: userName,
    );

    return ApiResponse.success(
      UserModel.fromJson(userData),
      statusCode: result.statusCode,
    );
  }

  Future<void> logout() async {
    // Try to revoke refresh token before clearing
    final refreshToken = _client.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _client.post<Map<String, dynamic>>(
          Endpoints.v1RevokeToken,
          body: {'refresh_token': refreshToken},
        );
      } catch (_) {}
    }
    await _client.clearSession();
  }

  Future<String?> getStoredRole() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.roleKey);
  }

  Future<String?> getStoredUserName() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.userNameKey);
  }

  Future<String?> getStoredUserEmail() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.userEmailKey);
  }

  Future<String?> getStoredUserId() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.userIdKey);
  }

  Future<SharedPreferences> _getPrefs() => SharedPreferences.getInstance();
}
