// upupa_frontend/lib/features/auth/models/user.dart

class User {
  final String id;
  final String email;
  final DateTime created;
  final DateTime updated;
  final bool isAdmin;

  User({
    required this.id,
    required this.email,
    required this.created,
    required this.updated,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      created: DateTime.parse(json['created']).toLocal(),
      updated: DateTime.parse(json['updated']).toLocal(),
      isAdmin: json['is_admin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
      'is_admin': isAdmin,
    };
  }
}
