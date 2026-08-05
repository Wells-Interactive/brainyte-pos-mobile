class AppConstants {
  static const String appName = '6th June';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://6june.nwekeuko.com',
  );
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String roleKey = 'role';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const Duration requestTimeout = Duration(seconds: 15);
}
