class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.available = true,
  });

  final int id;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool available;

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        category: (json['category'] ?? '').toString(),
        available: (json['available'] as num?)?.toInt() == 1 || json['available'] == true,
      );
}
