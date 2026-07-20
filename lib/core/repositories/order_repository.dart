import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/order.dart';

class OrderRepository {
  const OrderRepository(this._client);

  final ApiClient _client;

  Future<ApiResponse<Map<String, dynamic>>> submitOrder({
    required int tableId,
    required List<Map<String, dynamic>> items,
    required String instructions,
  }) async {
    return _client.post(
      Endpoints.orders,
      body: {
        'table_id': tableId,
        'instructions': instructions,
        'items': items,
      },
    );
  }

  Future<ApiResponse<List<OrderModel>>> fetchOrders() async {
    final result = await _client.get(Endpoints.status);
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
