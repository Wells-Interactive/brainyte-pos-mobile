import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/order.dart';

class OrderRepository {
  const OrderRepository(this._client);

  final ApiClient _client;

  /// Create a new order using the v1 orders endpoint.
  Future<ApiResponse<Map<String, dynamic>>> submitOrder({
    required int tableId,
    required List<Map<String, dynamic>> items,
    required String instructions,
    String paymentMethod = 'pending',
  }) async {
    return _client.post<Map<String, dynamic>>(
      Endpoints.v1Orders,
      body: {
        'table_id': tableId,
        'order_instructions': instructions,
        'instructions': instructions,
        'items': items,
        'payment_method': paymentMethod,
      },
      onData: (data) => data,
    );
  }

  /// Fetch orders list from the v1 orders endpoint (GET).
  Future<ApiResponse<Map<String, dynamic>>> fetchOrdersList({
    String? status,
    String? role,
    int limit = 100,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (role != null && role.isNotEmpty) params['role'] = role;

    return _client.get<Map<String, dynamic>>(
      Endpoints.v1Orders,
      queryParameters: params,
      onData: (data) => data,
    );
  }

  /// Fetch order history using v1 history endpoint.
  Future<ApiResponse<Map<String, dynamic>>> fetchOrderHistory({
    int? orderId,
    int? itemId,
    int limit = 50,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (orderId != null) params['order_id'] = orderId;
    if (itemId != null) params['item_id'] = itemId;

    return _client.get<Map<String, dynamic>>(
      Endpoints.v1OrderHistory,
      queryParameters: params,
      onData: (data) => data,
    );
  }

  /// Update order/item status using v1 order status endpoint.
  Future<ApiResponse<Map<String, dynamic>>> updateOrderStatus({
    int? orderId,
    int? itemId,
    required String status,
    String? paymentMethod,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (orderId != null) body['order_id'] = orderId;
    if (itemId != null) body['item_id'] = itemId;
    if (paymentMethod != null) body['payment_method'] = paymentMethod;

    return _client.post<Map<String, dynamic>>(
      Endpoints.v1OrderStatus,
      body: body,
      onData: (data) => data,
    );
  }

  /// Fetch active orders from legacy status endpoint (for kitchen/bar polling).
  Future<ApiResponse<List<OrderModel>>> fetchOrders() async {
    final result = await _client.getLegacy(Endpoints.legacyStatus);
    if (!result.success || result.data == null) {
      return ApiResponse.failure(result.error ?? 'Unable to load orders', statusCode: result.statusCode);
    }

    final raw = result.data!['order_items'] as List<dynamic>? ?? const <dynamic>[];
    final orders = raw
        .map((entry) => OrderModel.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList();

    return ApiResponse.success(orders, statusCode: result.statusCode);
  }
}
