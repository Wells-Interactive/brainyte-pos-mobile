import 'order_item.dart';

class OrderModel {
  const OrderModel({
    required this.id,
    required this.tableId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.waiterName,
    this.instructions,
    this.items = const [],
  });

  final int id;
  final int tableId;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? waiterName;
  final String? instructions;
  final List<OrderItemModel> items;

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        tableId: (json['table_id'] as num?)?.toInt() ?? 0,
        status: (json['status'] ?? 'pending').toString(),
        createdAt: (json['created_at'] ?? '').toString(),
        updatedAt: (json['updated_at'] ?? '').toString(),
        waiterName: json['waiter_name']?.toString(),
        instructions: json['instructions']?.toString(),
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((item) => OrderItemModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}
