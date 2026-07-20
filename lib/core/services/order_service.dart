import '../repositories/order_repository.dart';
import '../api/api_client.dart';

class OrderService {
  OrderService() : repository = OrderRepository(ApiClient.instance);

  final OrderRepository repository;
}
