class Note {
  final int id;
  final int userId;
  final int? categoryId;
  final String title;
  final String contentJson;
  final String? mindMapData;
  final String? audioUrl;
  final String colorHex;
  final bool isVault;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    required this.contentJson,
    this.mindMapData,
    this.audioUrl,
    this.colorHex = '#FFF9E6',
    this.isVault = false,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      categoryId: json['categoryId'],
      title: json['title'] ?? '',
      contentJson: json['contentJson'] ?? '',
      mindMapData: json['mindMapData'],
      audioUrl: json['audioUrl'],
      colorHex: json['colorHex'] ?? '#FFF9E6',
      isVault: json['isVault'] ?? false,
      isPinned: json['isPinned'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'title': title,
      'contentJson': contentJson,
      'mindMapData': mindMapData,
      'audioUrl': audioUrl,
      'colorHex': colorHex,
      'isVault': isVault,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Note copyWith({
    int? id,
    int? userId,
    int? categoryId,
    String? title,
    String? contentJson,
    String? mindMapData,
    String? audioUrl,
    String? colorHex,
    bool? isVault,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      contentJson: contentJson ?? this.contentJson,
      mindMapData: mindMapData ?? this.mindMapData,
      audioUrl: audioUrl ?? this.audioUrl,
      colorHex: colorHex ?? this.colorHex,
      isVault: isVault ?? this.isVault,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
