class CategoryItem {
  final int id;
  final int userId;
  final String name;
  final String colorCode;
  final String icon;

  CategoryItem({
    required this.id,
    required this.userId,
    required this.name,
    this.colorCode = '#FF6900',
    this.icon = 'folder',
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      name: json['name'] ?? '',
      colorCode: json['colorCode'] ?? '#FF6900',
      icon: json['icon'] ?? 'folder',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'colorCode': colorCode,
      'icon': icon,
    };
  }
}
