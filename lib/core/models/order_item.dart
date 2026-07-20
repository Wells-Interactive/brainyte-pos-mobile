class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
    required this.unitPrice,
    required this.status,
    this.routedTo,
    this.itemName,
  });

  final int id;
  final int orderId;
  final int menuItemId;
  final int quantity;
  final double unitPrice;
  final String status;
  final String? routedTo;
  final String? itemName;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        orderId: (json['order_id'] as num?)?.toInt() ?? 0,
        menuItemId: (json['menu_item_id'] as num?)?.toInt() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
        status: (json['status'] ?? 'pending').toString(),
        routedTo: json['routed_to']?.toString(),
        itemName: json['item_name']?.toString(),
      );
}
