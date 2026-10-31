class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isDemo = false,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final bool isDemo;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        role: (json['role'] ?? '').toString(),
        isDemo: json['is_demo'] == true || json['is_demo'] == 1,
      );
}
