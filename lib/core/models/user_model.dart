// lib/core/models/user_model.dart

class UserModel {
  final String name;
  final String email;
  final String role; // 'director' | 'therapist' | 'parent'

  const UserModel({
    required this.name,
    required this.email,
    required this.role,
  });

  String get displayRole {
    switch (role) {
      case 'director': return 'Director';
      case 'therapist': return 'Therapist';
      case 'parent': return 'Parent';
      default: return role;
    }
  }

  Map<String, dynamic> toMap() => {'name': name, 'email': email, 'role': role};

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        role: map['role'] ?? '',
      );
}
