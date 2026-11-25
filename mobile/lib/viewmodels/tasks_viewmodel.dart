import 'package:flutter/material.dart';
import '../models/task_item.dart';
import '../services/api_service.dart';

class TasksViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<TaskItem> _tasks = [];
  String? _priorityFilter; // null = All, 'Yüksek', 'Orta', 'Düşük'
  bool _isLoading = false;
  String? _error;

  List<TaskItem> get allTasks => _tasks;
  String? get priorityFilter => _priorityFilter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<TaskItem> get filteredTasks {
    if (_priorityFilter == null) return _tasks;
    return _tasks.where((t) => t.priority == _priorityFilter).toList();
  }

  List<TaskItem> get activeTasks =>
      filteredTasks.where((t) => !t.isCompleted).toList();

  List<TaskItem> get completedTasks =>
      filteredTasks.where((t) => t.isCompleted).toList();

  List<TaskItem> get uncompletedAllTasks =>
      _tasks.where((t) => !t.isCompleted).toList();

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _api.getTasks();
    } catch (_) {
      _error = 'Görevler yüklenemedi.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void setPriorityFilter(String? priority) {
    _priorityFilter = priority;
    notifyListeners();
  }

  Future<bool> addTask(
    String title, {
    String priority = 'Orta',
    DateTime? dueDate,
    int? parentId,
    int? noteId,
  }) async {
    try {
      await _api.createTask(
        title,
        priority: priority,
        dueDate: dueDate,
        parentId: parentId,
        noteId: noteId,
      );
      await loadTasks();
      return true;
    } catch (_) {
      _error = 'Görev eklenemedi.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(TaskItem task) async {
    try {
      await _api.updateTask(task);
      await loadTasks();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleComplete(int id) async {
    try {
      await _api.toggleTaskComplete(id);
      await loadTasks();
    } catch (_) {}
  }

  Future<void> deleteTask(int id) async {
    try {
      await _api.deleteTask(id);
      await loadTasks();
    } catch (_) {}
  }

  Future<void> reorderActiveTasks(int oldIndex, int newIndex) async {
    final active = List<TaskItem>.from(activeTasks);
    final moved = active.removeAt(oldIndex);
    active.insert(newIndex.clamp(0, active.length), moved);

    // Combine with completed tasks to preserve full ordering
    final completed = _tasks.where((t) => t.isCompleted).toList();
    final combined = [...active, ...completed];
    _tasks = combined;
    notifyListeners();

    try {
      await _api.reorderTasks(combined);
    } catch (_) {
      await loadTasks();
    }
  }

  void clear() {
    _tasks = [];
    _priorityFilter = null;
    notifyListeners();
  }
}
