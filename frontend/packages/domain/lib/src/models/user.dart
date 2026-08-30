import '../enums/user_role.dart';

/// Usuário autenticado do Flag Platform.
///
/// Shape de `GET /api/v1/auth/me` e do usuário dentro de
/// `POST /api/v1/auth/login`.
class User {
  /// Identificador UUID do usuário.
  final String id;

  final String name;

  final String email;

  /// Papel do usuário na plataforma.
  final UserRole role;

  /// Status da conta (ex: PENDING, ACTIVE, REJECTED).
  final String? status;

  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.status,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: UserRole.fromJson(json['role'] as String),
        status: json['status'] as String?,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.toJson(),
        if (status != null) 'status': status,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
