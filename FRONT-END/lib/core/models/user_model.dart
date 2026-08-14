// lib/core/models/user_model.dart

class UserModel {
  final int id;
  final String name;
  final String email;
  final String role; // 'director' | 'therapist' | 'parent'

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  String get displayRole {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'director':
        return 'Director';
      case 'therapist':
        return 'Therapist';
      case 'parent':
        return 'Parent';
      default:
        return role;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: int.tryParse('${map['id'] ?? 0}') ?? 0,
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        role: map['role'] ?? '',
      );
}
