class UserItem {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String token;

  UserItem({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.token,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'User',
      token: json['token'] ?? '',
    );
  }
}
