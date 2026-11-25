import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/external_data.dart';
import '../theme/app_theme.dart';

class DrawingScreen extends StatefulWidget {
  final String? initialDrawingJson;

  const DrawingScreen({super.key, this.initialDrawingJson});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final List<DrawingStroke> _strokes = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = const Color(0xFF1E1E1E);
  double _strokeWidth = 4.0;
  bool _isEraser = false;

  static const _palette = [
    Color(0xFF1E1E1E),
    Color(0xFFFF6900),
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFF8E24AA),
    Color(0xFFFDD835),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  void _loadInitial() {
    if (widget.initialDrawingJson == null || widget.initialDrawingJson!.trim().isEmpty) {
      return;
    }
    try {
      final list = jsonDecode(widget.initialDrawingJson!) as List;
      for (final item in list) {
        _strokes.add(DrawingStroke.fromJson(Map<String, dynamic>.from(item as Map)));
      }
    } catch (_) {}
  }

  void _saveAndClose() {
    if (_strokes.isEmpty) {
      Navigator.pop(context, '');
      return;
    }
    final jsonStr = jsonEncode(_strokes.map((s) => s.toJson()).toList());
    Navigator.pop(context, jsonStr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Çizim Motoru'),
        actions: [
          IconButton(
            tooltip: 'Geri Al',
            icon: const Icon(Icons.undo),
            onPressed: _strokes.isEmpty ? null : () => setState(() => _strokes.removeLast()),
          ),
          IconButton(
            tooltip: 'Temizle',
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            onPressed: _strokes.isEmpty ? null : () => setState(() => _strokes.clear()),
          ),
          IconButton(
            tooltip: 'Kaydet',
            icon: const Icon(Icons.check, color: AppTheme.xiaomiOrange),
            onPressed: _saveAndClose,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _currentPoints = [details.localPosition];
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _currentPoints = [..._currentPoints, details.localPosition];
                });
              },
              onPanEnd: (_) {
                if (_currentPoints.isNotEmpty) {
                  setState(() {
                    _strokes.add(
                      DrawingStroke(
                        points: List<Offset>.from(_currentPoints),
                        colorValue: _isEraser ? 0xFFFFFFFF : _selectedColor.toARGB32(),
                        strokeWidth: _isEraser ? _strokeWidth * 3 : _strokeWidth,
                        isEraser: _isEraser,
                      ),
                    );
                    _currentPoints = [];
                  });
                }
              },
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: CustomPaint(
                  painter: _CanvasPainter(
                    strokes: _strokes,
                    activePoints: _currentPoints,
                    activeColor: _isEraser ? Colors.white : _selectedColor,
                    activeWidth: _isEraser ? _strokeWidth * 3 : _strokeWidth,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.line_weight, size: 18, color: Colors.grey),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 1.5,
                        max: 16.0,
                        activeColor: AppTheme.xiaomiOrange,
                        onChanged: (v) => setState(() => _strokeWidth = v),
                      ),
                    ),
                    Text('${_strokeWidth.toStringAsFixed(0)} px',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ..._palette.map((color) {
                      final isSelected = !_isEraser && color.toARGB32() == _selectedColor.toARGB32();
                      return GestureDetector(
                        onTap: () => setState(() {
                          _isEraser = false;
                          _selectedColor = color;
                        }),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.xiaomiOrange : Colors.black12,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }),
                    FilterChip(
                      label: const Text('Silgi', style: TextStyle(fontSize: 12)),
                      avatar: const Icon(Icons.auto_fix_normal, size: 16),
                      selected: _isEraser,
                      selectedColor: AppTheme.xiaomiOrange.withValues(alpha: 0.2),
                      onSelected: (v) => setState(() => _isEraser = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> activePoints;
  final Color activeColor;
  final double activeWidth;

  _CanvasPainter({
    required this.strokes,
    required this.activePoints,
    required this.activeColor,
    required this.activeWidth,
  });

  void _drawStroke(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (points.length == 1) {
      canvas.drawCircle(points.first, width / 2, paint..style = PaintingStyle.fill);
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      _drawStroke(canvas, s.points, Color(s.colorValue), s.strokeWidth);
    }
    _drawStroke(canvas, activePoints, activeColor, activeWidth);
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
