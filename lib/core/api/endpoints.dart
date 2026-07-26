/// API Endpoints for the Brainyte Restaurant POS.
///
/// Supports both legacy (session-based) and v1 (Bearer token) endpoints.
class Endpoints {
  // ============================================================
  // Legacy Endpoints (session-based, for backward compatibility)
  // ============================================================
  static const String legacyBase = '/API';
  static const String legacyLogin = '/API/Login/index.php';
  static const String legacyRefreshToken = '/API/Auth/refresh.php';
  static const String legacyRevokeToken = '/API/Auth/revoke.php';
  static const String legacyMenu = '/API/Menu/index.php';
  static const String legacyOrdersCreate = '/API/Orders/create.php';
  static const String legacyOrdersList = '/API/Orders/list.php';
  static const String legacyOrdersHistory = '/API/Orders/history.php';
  static const String legacyOrdersStatus = '/API/Orders/status.php';
  static const String legacyStatus = '/API/Status/index.php';
  static const String legacyLiveEvents = '/API/Live Events/index.php';

  // ============================================================
  // v1 API Endpoints (Bearer token-based, for Flutter app)
  // ============================================================
  static const String v1Base = '/API/v1';

  // Auth
  static const String v1Login = '/API/v1/auth/index.php';
  static const String v1RefreshToken = '/API/v1/auth/refresh.php';
  static const String v1RevokeToken = '/API/v1/auth/revoke.php';

  // Menu
  static const String v1Menu = '/API/v1/menu/index.php';

  // Orders
  static const String v1Orders = '/API/v1/orders/index.php';
  static const String v1OrderStatus = '/API/v1/orders/status.php';
  static const String v1OrderHistory = '/API/v1/orders/history.php';

  // Reports & Stats
  static const String v1Reports = '/API/v1/reports/index.php';
}
