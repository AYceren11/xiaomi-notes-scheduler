import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/external_data.dart';
import '../models/schedule_item.dart';
import '../models/task_item.dart';
import '../services/api_service.dart';
import '../services/external_api_service.dart';

class SchedulerViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();
  final ExternalApiService _external = ExternalApiService();

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  List<ScheduleItem> _monthSchedules = [];
  List<PublicHoliday> _holidays = [];
  Map<String, WeatherDay> _weatherMap = {};
  bool _isLoading = false;
  String? _error;

  DateTime get selectedDate => _selectedDate;
  DateTime get focusedDay => _focusedDay;
  CalendarFormat get calendarFormat => _calendarFormat;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PublicHoliday> get holidays => _holidays;
  double? get currentTemp => _external.currentTemperature;
  int? get currentWeatherCode => _external.currentWeatherCode;

  List<ScheduleItem> get schedulesForSelectedDate => schedulesForDay(_selectedDate);

  List<ScheduleItem> schedulesForDay(DateTime day) {
    return _monthSchedules.where((s) => isSameDay(s.eventDate, day)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  PublicHoliday? holidayForDay(DateTime day) {
    for (final h in _holidays) {
      if (isSameDay(h.date, day)) return h;
    }
    return null;
  }

  WeatherDay? weatherForDay(DateTime day) {
    final key =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _weatherMap[key];
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.getSchedules(year: _focusedDay.year, month: _focusedDay.month),
        _external.getTurkishHolidays(_focusedDay.year),
        _external.getWeatherForecast(),
      ]);
      _monthSchedules = results[0] as List<ScheduleItem>;
      _holidays = results[1] as List<PublicHoliday>;
      _weatherMap = results[2] as Map<String, WeatherDay>;
    } catch (_) {
      _error = 'Zamanlayıcı verileri yüklenemedi.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectDate(DateTime date) async {
    final monthChanged = date.year != _focusedDay.year || date.month != _focusedDay.month;
    _selectedDate = date;
    _focusedDay = date;
    notifyListeners();
    if (monthChanged) {
      await loadAll();
    }
  }

  Future<void> onPageChanged(DateTime focused) async {
    final changed = focused.year != _focusedDay.year || focused.month != _focusedDay.month;
    _focusedDay = focused;
    notifyListeners();
    if (changed) {
      await loadAll();
    }
  }

  void setCalendarFormat(CalendarFormat format) {
    _calendarFormat = format;
    notifyListeners();
  }

  Future<bool> addSchedule({
    required String title,
    required String startTime,
    required String endTime,
    DateTime? date,
    int? taskId,
    int reminderMinutes = 15,
    String colorCode = '#FF6900',
  }) async {
    try {
      final item = ScheduleItem(
        id: 0,
        userId: 0,
        taskId: taskId,
        title: title,
        startTime: startTime,
        endTime: endTime,
        eventDate: date ?? _selectedDate,
        reminderMinutes: reminderMinutes,
        colorCode: colorCode,
      );
      await _api.createSchedule(item);
      await loadAll();
      return true;
    } catch (_) {
      _error = 'Plan kaydedilemedi. Saat aralığını kontrol edin.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSchedule(ScheduleItem item) async {
    try {
      await _api.updateSchedule(item);
      await loadAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteSchedule(int id) async {
    try {
      await _api.deleteSchedule(id);
      await loadAll();
    } catch (_) {}
  }

  Future<bool> assignTaskToHour(TaskItem task, int hour, {DateTime? date}) async {
    final startStr = '${hour.toString().padLeft(2, '0')}:00';
    final endHour = hour >= 23 ? 23 : hour + 1;
    final endMin = hour >= 23 ? '59' : '00';
    final endStr = '${endHour.toString().padLeft(2, '0')}:$endMin';

    String color = '#FF6900';
    if (task.priority == 'Yüksek') color = '#E53935';
    if (task.priority == 'Düşük') color = '#2196F3';

    return addSchedule(
      title: task.title,
      startTime: startStr,
      endTime: endStr,
      date: date ?? _selectedDate,
      taskId: task.id,
      reminderMinutes: 15,
      colorCode: color,
    );
  }

  void clear() {
    _monthSchedules = [];
    notifyListeners();
  }
}
