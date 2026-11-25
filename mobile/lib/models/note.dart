import 'dart:convert';

class Note {
  final int id;
  final int userId;
  final int? categoryId;
  final String? categoryName;
  final String title;
  final String contentJson;
  final String? mindMapData;
  final String? audioUrl;
  final String? drawingData;
  final String colorHex;
  final bool isVault;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.userId,
    this.categoryId,
    this.categoryName,
    required this.title,
    required this.contentJson,
    this.mindMapData,
    this.audioUrl,
    this.drawingData,
    this.colorHex = '#FFF9E6',
    this.isVault = false,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Extracts readable plain text preview from either Quill Delta JSON or raw text
  String get plainTextPreview {
    final trimmed = contentJson.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          final buf = StringBuffer();
          for (final op in decoded) {
            if (op is Map && op['insert'] is String) {
              buf.write(op['insert']);
            }
          }
          return buf.toString().trim();
        }
      } catch (_) {}
    }
    return trimmed;
  }

  bool get hasMindMap => mindMapData != null && mindMapData!.trim().isNotEmpty;
  bool get hasAudio => audioUrl != null && audioUrl!.trim().isNotEmpty;
  bool get hasDrawing => drawingData != null && drawingData!.trim().isNotEmpty;

  factory Note.fromJson(Map<String, dynamic> json) {
    final catObj = json['category'];
    return Note(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      categoryId: json['categoryId'],
      categoryName: catObj is Map ? catObj['name']?.toString() : json['categoryName']?.toString(),
      title: json['title'] ?? '',
      contentJson: json['contentJson'] ?? '',
      mindMapData: json['mindMapData'],
      audioUrl: json['audioUrl'],
      drawingData: json['drawingData'],
      colorHex: json['colorHex'] ?? '#FFF9E6',
      isVault: json['isVault'] ?? false,
      isPinned: json['isPinned'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
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
      'drawingData': drawingData,
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
    bool clearCategory = false,
    String? categoryName,
    String? title,
    String? contentJson,
    String? mindMapData,
    String? audioUrl,
    String? drawingData,
    String? colorHex,
    bool? isVault,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryName: clearCategory ? null : (categoryName ?? this.categoryName),
      title: title ?? this.title,
      contentJson: contentJson ?? this.contentJson,
      mindMapData: mindMapData ?? this.mindMapData,
      audioUrl: audioUrl ?? this.audioUrl,
      drawingData: drawingData ?? this.drawingData,
      colorHex: colorHex ?? this.colorHex,
      isVault: isVault ?? this.isVault,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
