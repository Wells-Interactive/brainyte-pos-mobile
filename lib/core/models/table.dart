class RestaurantTable {
  const RestaurantTable({
    required this.id,
    required this.name,
    required this.status,
  });

  final int id;
  final String name;
  final String status;

  factory RestaurantTable.fromJson(Map<String, dynamic> json) => RestaurantTable(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] ?? '').toString(),
        status: (json['status'] ?? 'available').toString(),
      );
}
