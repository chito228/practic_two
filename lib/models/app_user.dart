import 'role.dart';

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final Role role;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
  });

  AppUser copyWith({
    int? id,
    String? username,
    String? fullName,
    String? email,
    Role? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as int? ?? 0,
    username: json['username'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: Role.fromString(json['role'] as String?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'email': email,
    'role': role.toJson(),
  };
}
