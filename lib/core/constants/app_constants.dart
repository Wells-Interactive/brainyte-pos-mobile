class AppConstants {
  static const String appName = 'Brainyte Restaurant POS';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const String authTokenKey = 'auth_token';
  static const String roleKey = 'role';
  static const Duration requestTimeout = Duration(seconds: 15);
}
