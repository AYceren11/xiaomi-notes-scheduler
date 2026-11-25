import 'dart:ui';

class PublicHoliday {
  final DateTime date;
  final String localName;
  final String name;

  PublicHoliday({
    required this.date,
    required this.localName,
    required this.name,
  });

  factory PublicHoliday.fromJson(Map<String, dynamic> json) {
    return PublicHoliday(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      localName: json['localName'] ?? json['name'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class WeatherDay {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;

  WeatherDay({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
  });

  String get description => describeWmoCode(weatherCode);
  String get emoji => emojiForWmoCode(weatherCode);

  static String describeWmoCode(int code) {
    if (code == 0) return 'Açık Güneşli';
    if (code <= 3) return 'Parçalı Bulutlu';
    if (code <= 48) return 'Sisli';
    if (code <= 57) return 'Çiseleyen Yağmur';
    if (code <= 67) return 'Yağmurlu';
    if (code <= 77) return 'Karlı';
    if (code <= 82) return 'Sağanak Yağışlı';
    if (code <= 86) return 'Kar Sağanağı';
    return 'Fırtınalı';
  }

  static String emojiForWmoCode(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌦️';
    return '⛈️';
  }
}

class MindMapNode {
  String id;
  String text;
  String colorHex;
  List<MindMapNode> children;
  bool isCollapsed;

  MindMapNode({
    required this.id,
    required this.text,
    this.colorHex = '#FF6900',
    List<MindMapNode>? children,
    this.isCollapsed = false,
  }) : children = children ?? [];

  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    return MindMapNode(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      text: json['text']?.toString() ?? 'Düğüm',
      colorHex: json['color']?.toString() ?? '#FF6900',
      isCollapsed: json['isCollapsed'] == true,
      children: (json['children'] as List? ?? [])
          .map((c) => MindMapNode.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'color': colorHex,
        'isCollapsed': isCollapsed,
        'children': children.map((c) => c.toJson()).toList(),
      };
}

class DrawingStroke {
  final List<Offset> points;
  final int colorValue;
  final double strokeWidth;
  final bool isEraser;

  DrawingStroke({
    required this.points,
    required this.colorValue,
    required this.strokeWidth,
    this.isEraser = false,
  });

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    final pts = (json['points'] as List? ?? []).map((p) {
      final list = p as List;
      return Offset((list[0] as num).toDouble(), (list[1] as num).toDouble());
    }).toList();
    return DrawingStroke(
      points: pts,
      colorValue: json['color'] ?? 0xFF1E1E1E,
      strokeWidth: (json['width'] as num?)?.toDouble() ?? 4.0,
      isEraser: json['eraser'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => [p.dx, p.dy]).toList(),
        'color': colorValue,
        'width': strokeWidth,
        'eraser': isEraser,
      };
}
