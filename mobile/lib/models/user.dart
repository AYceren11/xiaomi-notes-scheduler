class UserItem {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String token;
  final bool isActive;
  final DateTime? createdAt;
  final int notesCount;
  final int tasksCount;
  final int schedulesCount;

  UserItem({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.token = '',
    this.isActive = true,
    this.createdAt,
    this.notesCount = 0,
    this.tasksCount = 0,
    this.schedulesCount = 0,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'User',
      token: json['token'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      notesCount: json['notesCount'] ?? 0,
      tasksCount: json['tasksCount'] ?? 0,
      schedulesCount: json['schedulesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'token': token,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'notesCount': notesCount,
      'tasksCount': tasksCount,
      'schedulesCount': schedulesCount,
    };
  }
}
