import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_response.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<ApiResponse<UserModel>> login({required String email, required String password}) async {
    // Use session-based auth - backend uses PHP sessions via cookies
    final result = await _client.post(
      '/API/Login/index.php',
      body: {'email': email, 'password': password},
    );

    if (!result.success || result.data == null) {
      return ApiResponse.failure(result.error ?? 'Login failed', statusCode: result.statusCode);
    }

    final userData = result.data!['user'] as Map<String, dynamic>?;
    if (userData == null) {
      return ApiResponse.failure('Invalid response from server', statusCode: result.statusCode);
    }

    // Persist session info locally for role detection
    final prefs = await SharedPreferences.getInstance();
    final role = (userData['role']?.toString() ?? 'waiter').toLowerCase();
    await prefs.setString(AppConstants.roleKey, role);
    await prefs.setString('user_id', (userData['id'] as num?)?.toInt().toString() ?? '');
    await prefs.setString('user_name', userData['name']?.toString() ?? '');

    return ApiResponse.success(
      UserModel.fromJson(userData),
      statusCode: result.statusCode,
    );
  }

  Future<void> logout() async {
    await _client.clearSession();
  }

  Future<String?> getStoredRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.roleKey);
  }

  Future<String?> getStoredUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }
}
