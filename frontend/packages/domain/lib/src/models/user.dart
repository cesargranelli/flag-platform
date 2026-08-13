/// Usuário autenticado do Flag Platform.
///
/// Shape de `GET /api/v1/auth/me` e do usuário dentro de
/// `POST /api/v1/auth/login`.
class User {
  /// Identificador UUID do usuário.
  final String id;

  final String name;

  final String email;

  /// Role do usuário (ex: ORGANIZER, MESA, ADMIN).
  final String role;

  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
