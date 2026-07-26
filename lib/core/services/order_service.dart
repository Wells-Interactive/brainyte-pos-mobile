import '../repositories/order_repository.dart';
import '../api/api_client.dart';
import '../api/api_response.dart';
import '../models/order.dart';

class OrderService {
  OrderService() : repository = OrderRepository(ApiClient.instance);

  final OrderRepository repository;

  /// Submit an order to the backend.
  Future<ApiResponse<Map<String, dynamic>>> submitOrder({
    required int tableId,
    required List<Map<String, dynamic>> items,
    required String instructions,
    String paymentMethod = 'pending',
  }) {
    return repository.submitOrder(
      tableId: tableId,
      items: items,
      instructions: instructions,
      paymentMethod: paymentMethod,
    );
  }

  /// Fetch active orders (for kitchen/bar).
  Future<ApiResponse<List<OrderModel>>> fetchOrders() {
    return repository.fetchOrders();
  }

  /// Fetch orders list with optional filters.
  Future<ApiResponse<Map<String, dynamic>>> fetchOrdersList({
    String? status,
    String? role,
    int limit = 100,
  }) {
    return repository.fetchOrdersList(
      status: status,
      role: role,
      limit: limit,
    );
  }

  /// Update order/item status.
  Future<ApiResponse<Map<String, dynamic>>> updateOrderStatus({
    int? orderId,
    int? itemId,
    required String status,
    String? paymentMethod,
  }) {
    return repository.updateOrderStatus(
      orderId: orderId,
      itemId: itemId,
      status: status,
      paymentMethod: paymentMethod,
    );
  }
}
