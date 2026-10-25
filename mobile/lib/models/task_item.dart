class TaskItem {
  final int id;
  final int userId;
  final int? noteId;
  final int? parentId;
  final String title;
  final bool isCompleted;
  final String priority; // 'Düşük', 'Orta', 'Yüksek'
  final int orderIndex;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<TaskItem> subtasks;

  TaskItem({
    required this.id,
    required this.userId,
    this.noteId,
    this.parentId,
    required this.title,
    this.isCompleted = false,
    this.priority = 'Orta',
    this.orderIndex = 0,
    this.dueDate,
    required this.createdAt,
    this.completedAt,
    this.subtasks = const [],
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      noteId: json['noteId'],
      parentId: json['parentId'],
      title: json['title'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      priority: json['priority'] ?? 'Orta',
      orderIndex: json['orderIndex'] ?? 0,
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
      subtasks: json['subtasks'] != null
          ? (json['subtasks'] as List).map((i) => TaskItem.fromJson(i)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'noteId': noteId,
      'parentId': parentId,
      'title': title,
      'isCompleted': isCompleted,
      'priority': priority,
      'orderIndex': orderIndex,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  TaskItem copyWith({
    int? id,
    int? userId,
    int? noteId,
    int? parentId,
    String? title,
    bool? isCompleted,
    String? priority,
    int? orderIndex,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? completedAt,
    List<TaskItem>? subtasks,
  }) {
    return TaskItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      noteId: noteId ?? this.noteId,
      parentId: parentId ?? this.parentId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      orderIndex: orderIndex ?? this.orderIndex,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      subtasks: subtasks ?? this.subtasks,
    );
  }
}
