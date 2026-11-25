import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/external_data.dart';
import '../models/schedule_item.dart';
import '../models/task_item.dart';
import '../theme/app_theme.dart';
import '../viewmodels/scheduler_viewmodel.dart';
import '../viewmodels/tasks_viewmodel.dart';

class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  final ScrollController _timelineScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Auto-scroll near 08:00 for quick daily view
      if (_timelineScroll.hasClients) {
        _timelineScroll.jumpTo(8 * 68.0);
      }
    });
  }

  @override
  void dispose() {
    _timelineScroll.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppTheme.xiaomiOrange;
    }
  }

  /// Year & Month quick selector dialog (Yıllık / Aylık Seçici)
  void _showYearMonthPicker(SchedulerViewModel vm) {
    int selectedYear = vm.focusedDay.year;
    int selectedMonth = vm.focusedDay.month;
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yıl & Ay Seçin'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setDlgState(() => selectedYear--),
                    ),
                    Text(
                      '$selectedYear',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setDlgState(() => selectedYear++),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: 12,
                  itemBuilder: (_, idx) {
                    final m = idx + 1;
                    final isSel = m == selectedMonth;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setDlgState(() => selectedMonth = m),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSel ? AppTheme.xiaomiOrange : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          months[idx],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.xiaomiOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                vm.selectDate(DateTime(selectedYear, selectedMonth, 1));
              },
              child: const Text('Git'),
            ),
          ],
        ),
      ),
    );
  }

  /// Create or Edit Schedule Dialog (with form validation, task link, reminder alarm)
  void _showScheduleDialog({int? initialHour, ScheduleItem? existing}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final tasks = context.read<TasksViewModel>().uncompletedAllTasks;

    TimeOfDay startTime = existing != null
        ? TimeOfDay(hour: existing.startHour, minute: existing.startMinute)
        : TimeOfDay(hour: initialHour ?? 9, minute: 0);
    TimeOfDay endTime = existing != null
        ? TimeOfDay(hour: existing.endHour, minute: existing.endMinute)
        : TimeOfDay(
            hour: (initialHour ?? 9) >= 23 ? 23 : (initialHour ?? 9) + 1,
            minute: (initialHour ?? 9) >= 23 ? 59 : 0,
          );

    int? selectedTaskId = existing?.taskId;
    int reminderMinutes = existing?.reminderMinutes ?? 15;
    String colorCode = existing?.colorCode ?? '#FF6900';
    String? timeError;

    const colors = ['#FF6900', '#2196F3', '#4CAF50', '#9C27B0', '#E53935', '#009688'];

    String fmtTod(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'Zaman Bloğuna Plan Ekle' : 'Planı Düzenle'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Etkinlik / Ders / Görev Adı',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Başlık zorunludur.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (tasks.isNotEmpty) ...[
                    DropdownButtonFormField<int?>(
                      initialValue: tasks.any((t) => t.id == selectedTaskId) ? selectedTaskId : null,
                      decoration: const InputDecoration(
                        labelText: 'Görevle İlişkilendir (Opsiyonel)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Bağımsız Etkinlik')),
                        ...tasks.map((t) => DropdownMenuItem<int?>(
                              value: t.id,
                              child: Text(t.title, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) {
                        setDlgState(() {
                          selectedTaskId = v;
                          if (v != null && titleCtrl.text.trim().isEmpty) {
                            final t = tasks.firstWhere((e) => e.id == v);
                            titleCtrl.text = t.title;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text('Başla: ${fmtTod(startTime)}',
                              style: const TextStyle(fontSize: 12)),
                          onPressed: () async {
                            final t = await showTimePicker(
                                context: context, initialTime: startTime);
                            if (t != null) setDlgState(() => startTime = t);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time_filled, size: 16),
                          label: Text('Bitir: ${fmtTod(endTime)}',
                              style: const TextStyle(fontSize: 12)),
                          onPressed: () async {
                            final t = await showTimePicker(
                                context: context, initialTime: endTime);
                            if (t != null) setDlgState(() => endTime = t);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (timeError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(timeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      const Text('Hatırlatıcı Alarm:', style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      DropdownButton<int>(
                        value: reminderMinutes,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Kapalı')),
                          DropdownMenuItem(value: 5, child: Text('5 dk önce')),
                          DropdownMenuItem(value: 10, child: Text('10 dk önce')),
                          DropdownMenuItem(value: 15, child: Text('15 dk önce')),
                          DropdownMenuItem(value: 30, child: Text('30 dk önce')),
                          DropdownMenuItem(value: 60, child: Text('1 saat önce')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDlgState(() => reminderMinutes = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: colors.map((hex) {
                      final c = _parseColor(hex);
                      final sel = hex == colorCode;
                      return GestureDetector(
                        onTap: () => setDlgState(() => colorCode = hex),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: c,
                          child: sel ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await this.context.read<SchedulerViewModel>().deleteSchedule(existing.id);
                },
                child: const Text('Sil', style: TextStyle(color: Colors.red)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.xiaomiOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final sMin = startTime.hour * 60 + startTime.minute;
                final eMin = endTime.hour * 60 + endTime.minute;
                if (eMin <= sMin) {
                  setDlgState(() => timeError = 'Bitiş saati başlangıçtan sonra olmalıdır.');
                  return;
                }
                Navigator.pop(ctx);
                final vm = this.context.read<SchedulerViewModel>();
                if (existing == null) {
                  await vm.addSchedule(
                    title: titleCtrl.text.trim(),
                    startTime: fmtTod(startTime),
                    endTime: fmtTod(endTime),
                    taskId: selectedTaskId,
                    reminderMinutes: reminderMinutes,
                    colorCode: colorCode,
                  );
                } else {
                  await vm.updateSchedule(
                    ScheduleItem(
                      id: existing.id,
                      userId: existing.userId,
                      taskId: selectedTaskId,
                      title: titleCtrl.text.trim(),
                      startTime: fmtTod(startTime),
                      endTime: fmtTod(endTime),
                      eventDate: existing.eventDate,
                      reminderMinutes: reminderMinutes,
                      colorCode: colorCode,
                    ),
                  );
                }
              },
              child: Text(existing == null ? 'Kaydet' : 'Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SchedulerViewModel>();
    final tasksVm = context.watch<TasksViewModel>();
    final daySchedules = vm.schedulesForSelectedDate;
    final holiday = vm.holidayForDay(vm.selectedDate);
    final weather = vm.weatherForDay(vm.selectedDate);
    final pendingTasks = tasksVm.uncompletedAllTasks;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showYearMonthPicker(vm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('MMMM yyyy', 'tr_TR').format(vm.focusedDay),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.arrow_drop_down, color: AppTheme.xiaomiOrange),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Bugüne Dön',
            icon: const Icon(Icons.today),
            onPressed: () => vm.selectDate(DateTime.now()),
          ),
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: vm.loadAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // TableCalendar (Yıllık / Aylık / 7 Günlük Haftalık Band)
          Container(
            color: Colors.white,
            child: TableCalendar<ScheduleItem>(
              locale: 'tr_TR',
              firstDay: DateTime(2024, 1, 1),
              lastDay: DateTime(2030, 12, 31),
              focusedDay: vm.focusedDay,
              selectedDayPredicate: (d) => isSameDay(d, vm.selectedDate),
              calendarFormat: vm.calendarFormat,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Ay',
                CalendarFormat.twoWeeks: '2 Hafta',
                CalendarFormat.week: 'Hafta',
              },
              onFormatChanged: vm.setCalendarFormat,
              onDaySelected: (selected, focused) => vm.selectDate(selected),
              onPageChanged: vm.onPageChanged,
              eventLoader: vm.schedulesForDay,
              holidayPredicate: (day) => vm.holidayForDay(day) != null,
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: false,
                formatButtonShowsNext: false,
                headerPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppTheme.xiaomiOrange.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppTheme.xiaomiOrange,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.xiaomiOrange,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.indigo,
                  shape: BoxShape.circle,
                ),
                holidayDecoration: BoxDecoration(
                  border: Border.all(color: Colors.redAccent),
                  shape: BoxShape.circle,
                ),
                holidayTextStyle: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // External APIs Info Strip (Open-Meteo Weather + Nager.Date Public Holiday)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F2),
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('d MMMM EEEE', 'tr_TR').format(vm.selectedDate),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (weather != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${weather.emoji} ${weather.minTemp.round()}° / ${weather.maxTemp.round()}° • ${weather.description}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      )
                    else if (vm.currentTemp != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${WeatherDay.emojiForWmoCode(vm.currentWeatherCode ?? 0)} ${vm.currentTemp!.round()}°C (Open-Meteo)',
                          style: TextStyle(fontSize: 11.5, color: Colors.blue.shade900),
                        ),
                      ),
                  ],
                ),
                if (holiday != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flag_outlined, size: 15, color: Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Resmî Tatil (Nager.Date): ${holiday.localName}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Drag-and-Drop Pending Tasks Tray (Görevleri 24 Saatlik Matrise Sürükle-Bırak)
          if (pendingTasks.isNotEmpty)
            Container(
              height: 54,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: pendingTasks.length,
                itemBuilder: (context, idx) {
                  final task = pendingTasks[idx];
                  final chip = Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.xiaomiOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.xiaomiOrange.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.drag_indicator, size: 15, color: AppTheme.xiaomiOrange),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  return Draggable<TaskItem>(
                    data: task,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Transform.scale(scale: 1.05, child: chip),
                    ),
                    childWhenDragging: Opacity(opacity: 0.4, child: chip),
                    child: chip,
                  );
                },
              ),
            ),

          const Divider(height: 1),

          // 24-Hour Vertical Time Matrix (00:00 - 23:59) with DragTarget<TaskItem>
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.xiaomiOrange))
                : ListView.builder(
                    controller: _timelineScroll,
                    padding: const EdgeInsets.only(top: 6, bottom: 88),
                    itemCount: 24,
                    itemBuilder: (context, hour) {
                      final hourEvents =
                          daySchedules.where((s) => s.startHour == hour).toList();
                      final timeLabel = '${hour.toString().padLeft(2, '0')}:00';

                      return DragTarget<TaskItem>(
                        onAcceptWithDetails: (details) async {
                          final task = details.data;
                          final ok = await vm.assignTaskToHour(task, hour);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? '"${task.title}" → $timeLabel bloğuna atandı!'
                                    : 'Görev saat bloğuna atanamadı.'),
                                backgroundColor: ok ? Colors.green : Colors.red,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isHovering = candidateData.isNotEmpty;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 68,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isHovering
                                  ? AppTheme.xiaomiOrange.withValues(alpha: 0.14)
                                  : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200, width: 0.8),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    timeLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isHovering
                                          ? AppTheme.xiaomiOrange
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                const VerticalDivider(width: 20, thickness: 1),
                                Expanded(
                                  child: hourEvents.isNotEmpty
                                      ? Row(
                                          children: hourEvents.map((ev) {
                                            final evColor = _parseColor(ev.colorCode);
                                            return Expanded(
                                              child: GestureDetector(
                                                onTap: () => _showScheduleDialog(existing: ev),
                                                child: Container(
                                                  margin: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: evColor.withValues(alpha: 0.14),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border(
                                                      left: BorderSide(color: evColor, width: 4),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        ev.title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 12.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF1E1E1E),
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            ev.formattedRange,
                                                            style: TextStyle(
                                                              fontSize: 10.5,
                                                              color: Colors.grey.shade700,
                                                            ),
                                                          ),
                                                          if (ev.reminderMinutes > 0) ...[
                                                            const SizedBox(width: 6),
                                                            Icon(Icons.alarm,
                                                                size: 11, color: evColor),
                                                          ],
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        )
                                      : GestureDetector(
                                          onTap: () => _showScheduleDialog(initialHour: hour),
                                          child: Container(
                                            color: Colors.transparent,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              isHovering
                                                  ? '⬇ Buraya bırak ($timeLabel)'
                                                  : '+ Plan ekle veya görev sürükle',
                                              style: TextStyle(
                                                color: isHovering
                                                    ? AppTheme.xiaomiOrange
                                                    : Colors.grey.shade400,
                                                fontWeight: isHovering
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
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
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'scheduler_fab',
        onPressed: () => _showScheduleDialog(initialHour: DateTime.now().hour),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
