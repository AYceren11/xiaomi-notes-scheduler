import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final ApiService _api = ApiService();
  List<TaskItem> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await _api.getTasks();
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleComplete(int id) async {
    await _api.toggleTaskComplete(id);
    _loadTasks();
  }

  void _showAddTaskDialog([int? parentId]) {
    final titleCtrl = TextEditingController();
    String priority = 'Orta';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(parentId != null ? 'Alt Görev Ekle' : 'Yeni Görev Ekle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Görev açıklaması...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Öncelik: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      DropdownButton<String>(
                        value: priority,
                        items: ['Düşük', 'Orta', 'Yüksek'].map((p) {
                          return DropdownMenuItem(value: p, child: Text(p));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => priority = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.xiaomiOrange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final text = titleCtrl.text.trim();
                    if (text.isNotEmpty) {
                      Navigator.pop(dialogCtx);
                      await _api.createTask(text, priority: priority, parentId: parentId);
                      if (mounted) _loadTasks();
                    }
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color bg;
    Color fg;
    switch (priority) {
      case 'Yüksek':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      case 'Düşük':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTasks = _tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = _tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görevler & Checklist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.xiaomiOrange))
          : RefreshIndicator(
              color: AppTheme.xiaomiOrange,
              onRefresh: _loadTasks,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  if (activeTasks.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Devam Eden Görevler',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...activeTasks.map((t) => _buildTaskTile(t)),
                  ],
                  if (completedTasks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Tamamlananlar (${completedTasks.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    ...completedTasks.map((t) => _buildTaskTile(t)),
                  ],
                  if (_tasks.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Harika! Bekleyen görev yok.',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildTaskTile(TaskItem task) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Checkbox(
              value: task.isCompleted,
              activeColor: AppTheme.xiaomiOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              onChanged: (_) => _toggleComplete(task.id),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? Colors.grey : Colors.black87,
              ),
            ),
            subtitle: task.dueDate != null
                ? Text(
                    DateFormat('dd MMM yyyy').format(task.dueDate!),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPriorityBadge(task.priority),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.grey),
                  tooltip: 'Alt Görev Ekle',
                  onPressed: () => _showAddTaskDialog(task.id),
                ),
              ],
            ),
          ),
          if (task.subtasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 16, bottom: 8),
              child: Column(
                children: task.subtasks.map((sub) {
                  return Row(
                    children: [
                      Checkbox(
                        value: sub.isCompleted,
                        activeColor: AppTheme.xiaomiOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (_) => _toggleComplete(sub.id),
                      ),
                      Expanded(
                        child: Text(
                          sub.title,
                          style: TextStyle(
                            fontSize: 13,
                            decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                            color: sub.isCompleted ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
