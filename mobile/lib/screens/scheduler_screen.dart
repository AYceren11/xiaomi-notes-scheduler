import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  DateTime _selectedDate = DateTime.now();

  final Map<int, List<Map<String, String>>> _events = {
    9: [
      {'title': 'BLM4587 Mobil Uygulama Dersi', 'color': '#2196F3', 'duration': '9:00 - 10:30'}
    ],
    11: [
      {'title': 'Web API & PostgreSQL Migration Testi', 'color': '#FF6900', 'duration': '11:00 - 12:00'}
    ],
    14: [
      {'title': 'Xiaomi Notes UI Çizimleri', 'color': '#4CAF50', 'duration': '14:00 - 15:30'}
    ],
    17: [
      {'title': 'Haftalık İlerleme Videosu Kaydı', 'color': '#9C27B0', 'duration': '17:00 - 18:00'}
    ],
  };

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppTheme.xiaomiOrange;
    }
  }

  void _addEventDialog(int hour) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Saat ${hour.toString().padLeft(2, '0')}:00 için Plan Ekle'),
          content: TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(
              hintText: 'Etkinlik / Ders / Görev adı...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.xiaomiOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final text = titleCtrl.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _events.putIfAbsent(hour, () => []).add({
                      'title': text,
                      'color': '#FF6900',
                      'duration': '${hour.toString().padLeft(2, '0')}:00 - ${(hour + 1).toString().padLeft(2, '0')}:00',
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'tr_TR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('24 Saatlik Zamanlayıcı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(
                    () => _selectedDate = _selectedDate.subtract(const Duration(days: 1)),
                  ),
                ),
                Text(
                  dateFormat.format(_selectedDate),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(
                    () => _selectedDate = _selectedDate.add(const Duration(days: 1)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 24-hour vertical timeline matrix
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: 24,
              itemBuilder: (context, hour) {
                final hourEvents = _events[hour] ?? [];
                final timeLabel = '${hour.toString().padLeft(2, '0')}:00';

                return Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 24, thickness: 1),
                      Expanded(
                        child: hourEvents.isNotEmpty
                            ? Row(
                                children: hourEvents.map((ev) {
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _parseColor(ev['color'] ?? '#FF6900').withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border(
                                          left: BorderSide(
                                            color: _parseColor(ev['color'] ?? '#FF6900'),
                                            width: 4,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            ev['title'] ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E1E1E),
                                            ),
                                          ),
                                          Text(
                                            ev['duration'] ?? '',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            : GestureDetector(
                                onTap: () => _addEventDialog(hour),
                                child: Container(
                                  color: Colors.transparent,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '+ Saat bloğuna görev ata',
                                    style: TextStyle(
                                      color: Colors.grey.shade300,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
