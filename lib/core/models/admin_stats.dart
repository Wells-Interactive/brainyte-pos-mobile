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

  /// Parse v1 reports endpoint response format.
  ///
  /// v1 returns { total_revenue, completed_orders, summary_day,
  ///              tables: [{id, name, status}], ... }
  factory AdminStats.fromV1Json(Map<String, dynamic> json) {
    final tables = (json['tables'] as List<dynamic>? ?? const <dynamic>[])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();

    final occupied = tables.where((table) => (table['status']?.toString() ?? 'available') != 'available').length;
    final available = tables.length - occupied;

    // v1 reports don't have 'sales' - use top_items as recent instead
    final topItems = (json['top_items'] as List<dynamic>? ?? const <dynamic>[])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();

    return AdminStats(
      ordersToday: (json['completed_orders'] as num?)?.toInt() ?? 0,
      revenueToday: (json['summary_day'] as num?)?.toDouble() ?? 0,
      occupiedTables: occupied,
      availableTables: available,
      kitchenQueue: (json['total_kitchen_orders'] as num?)?.toInt() ?? 0,
      barQueue: (json['total_bar_orders'] as num?)?.toInt() ?? 0,
      activeWaiters: (tables.where((t) => t['status'] == 'occupied').length).clamp(0, 999),
      recentOrders: topItems,
    );
  }
}
