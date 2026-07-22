class User {
  final int id;
  final String email;
  final String name;
  final String role;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        email: json['email'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
