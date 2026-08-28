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
  static const String legacySettings = '/API/Settings/index.php';
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

  // Status (tables and order items)
  static const String v1Status = '/API/v1/status/index.php';

  // Reports & Stats
  static const String v1Reports = '/API/v1/reports/index.php';
  static const String v1Delivery = '/API/v1/delivery/index.php';
  static const String v1CustomerRegistration = '/API/v1/auth/customer.php';
  static const String v1CustomerPasswordReset = '/API/v1/auth/customer_password_reset.php';
  static const String v1CustomerBilling = '/API/v1/customer/billing.php';
  static const String v1Payments = '/API/v1/payments/index.php';
  static const String v1Operations = '/API/v1/operations/index.php';
  static const String v1Miscellaneous = '/API/v1/miscellaneous/index.php';
  static const String v1AdminCustomers = '/API/v1/admin/customers.php';
  static const String v1Tables = '/API/v1/tables/index.php';
}
