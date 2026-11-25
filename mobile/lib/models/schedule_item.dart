class ScheduleItem {
  final int id;
  final int userId;
  final int? taskId;
  final String? taskTitle;
  final String title;
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final DateTime eventDate;
  final int reminderMinutes;
  final String colorCode;

  ScheduleItem({
    required this.id,
    required this.userId,
    this.taskId,
    this.taskTitle,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.eventDate,
    this.reminderMinutes = 15,
    this.colorCode = '#FF6900',
  });

  int get startHour {
    final parts = startTime.split(':');
    return parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 9) : 9;
  }

  int get startMinute {
    final parts = startTime.split(':');
    return parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  }

  int get endHour {
    final parts = endTime.split(':');
    return parts.isNotEmpty ? (int.tryParse(parts[0]) ?? (startHour + 1).clamp(0, 23)) : 10;
  }

  int get endMinute {
    final parts = endTime.split(':');
    return parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  }

  String get formattedRange => '${_shortTime(startTime)} - ${_shortTime(endTime)}';

  static String _shortTime(String t) {
    final parts = t.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return t;
  }

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      taskId: json['taskId'],
      taskTitle: json['taskTitle'],
      title: json['title'] ?? '',
      startTime: _shortTime(json['startTime']?.toString() ?? '09:00'),
      endTime: _shortTime(json['endTime']?.toString() ?? '10:00'),
      eventDate: json['eventDate'] != null
          ? DateTime.tryParse(json['eventDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reminderMinutes: json['reminderMinutes'] ?? 15,
      colorCode: json['colorCode'] ?? '#FF6900',
    );
  }

  Map<String, dynamic> toRequestJson() {
    final y = eventDate.year.toString().padLeft(4, '0');
    final m = eventDate.month.toString().padLeft(2, '0');
    final d = eventDate.day.toString().padLeft(2, '0');
    return {
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'eventDate': '$y-$m-$d',
      'taskId': taskId,
      'reminderMinutes': reminderMinutes,
      'colorCode': colorCode,
    };
  }
}
