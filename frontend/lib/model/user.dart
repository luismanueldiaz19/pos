class User {
  final int? id;
  final String? name;
  final String? username;
  final String? email;
  final List<String> roles;
  final String? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    this.name,
    this.username,
    this.email,
    this.roles = const [],
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  User copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    List<String>? roles,
    String? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    username: username ?? this.username,
    email: email ?? this.email,
    roles: roles ?? this.roles,
    emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory User.fromJson(Map<String, dynamic> json) {
    List<String> parsedRoles = [];
    if (json["roles"] != null) {
      if (json["roles"] is List) {
        parsedRoles = (json["roles"] as List).map((r) {
          if (r is Map) return (r["name"] ?? '').toString();
          return r.toString();
        }).where((r) => r.isNotEmpty).toList();
      }
    }

    return User(
      id: json["id"],
      name: json["name"],
      username: json["username"],
      email: json["email"],
      roles: parsedRoles,
      emailVerifiedAt: json["email_verified_at"],
      createdAt: json["created_at"] != null
          ? DateTime.tryParse(json["created_at"] ?? '')
          : null,
      updatedAt: json["updated_at"] != null
          ? DateTime.tryParse(json["updated_at"] ?? '')
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "username": username,
    "email": email,
    "roles": roles,
    "email_verified_at": emailVerifiedAt,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

class AuthResponse {
  final bool status;
  final User user;
  final List<String> roles;
  final List<String> permissions;
  final String token;

  AuthResponse({
    required this.status,
    required this.user,
    required this.roles,
    required this.permissions,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return AuthResponse(
      status: json['status'],
      user: User.fromJson(data['user']),
      roles: List<String>.from(data['roles']),
      permissions: List<String>.from(data['permissions']),
      token: data['token'],
    );
  }
}
