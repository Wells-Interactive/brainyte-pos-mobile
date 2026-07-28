class AppConstants {
  static const String appName = '6th June';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://6june.nwekeuko.com',
  );
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String roleKey = 'role';
  static const Duration requestTimeout = Duration(seconds: 15);
}
