class AdminStats {
  const AdminStats({
    required this.ordersToday,
    required this.revenueToday,
    required this.occupiedTables,
    required this.availableTables,
    required this.kitchenQueue,
    required this.barQueue,
    required this.activeWaiters,
    required this.recentOrders,
  });

  final int ordersToday;
  final double revenueToday;
  final int occupiedTables;
  final int availableTables;
  final int kitchenQueue;
  final int barQueue;
  final int activeWaiters;
  final List<Map<String, dynamic>> recentOrders;

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final tables = (json['tables'] as List<dynamic>? ?? const <dynamic>[])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();

    final occupied = tables.where((table) => (table['status']?.toString() ?? 'available') != 'available').length;
    final available = tables.length - occupied;

    return AdminStats(
      ordersToday: (json['completed_orders'] as num?)?.toInt() ?? 0,
      revenueToday: (json['summary_day'] as num?)?.toDouble() ?? 0,
      occupiedTables: occupied,
      availableTables: available,
      kitchenQueue: (json['total_kitchen_orders'] as num?)?.toInt() ?? 0,
      barQueue: (json['total_bar_orders'] as num?)?.toInt() ?? 0,
      activeWaiters: ((json['sales'] as List<dynamic>? ?? const <dynamic>[]).length).clamp(0, 999),
      recentOrders: (json['sales'] as List<dynamic>? ?? const <dynamic>[])
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList(),
    );
  }
}
