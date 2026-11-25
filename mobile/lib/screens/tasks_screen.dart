import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task_item.dart';
import '../theme/app_theme.dart';
import '../viewmodels/scheduler_viewmodel.dart';
import '../viewmodels/tasks_viewmodel.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  void _showTaskDialog({TaskItem? existing, int? parentId}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    String priority = existing?.priority ?? 'Orta';
    DateTime? dueDate = existing?.dueDate;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                existing != null
                    ? 'Görevi Düzenle'
                    : (parentId != null ? 'Alt Görev Ekle' : 'Yeni Görev Ekle'),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Görev Başlığı',
                        hintText: 'Yapılacak görevi yazın...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Görev başlığı zorunludur.';
                        }
                        if (v.trim().length > 250) {
                          return 'En fazla 250 karakter olabilir.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Öncelik: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        DropdownButton<String>(
                          value: priority,
                          items: ['Düşük', 'Orta', 'Yüksek']
                              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => priority = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('Son Tarih: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            dueDate != null
                                ? DateFormat('dd MMM yyyy', 'tr_TR').format(dueDate!)
                                : 'Tarih Seç',
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dueDate ?? DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setDialogState(() => dueDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
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
                    if (!formKey.currentState!.validate()) return;
                    final text = titleCtrl.text.trim();
                    Navigator.pop(dialogCtx);
                    final vm = this.context.read<TasksViewModel>();
                    if (existing != null) {
                      await vm.updateTask(
                        existing.copyWith(
                          title: text,
                          priority: priority,
                          dueDate: dueDate,
                        ),
                      );
                    } else {
                      await vm.addTask(
                        text,
                        priority: priority,
                        dueDate: dueDate,
                        parentId: parentId,
                      );
                    }
                  },
                  child: Text(existing != null ? 'Güncelle' : 'Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAssignToSchedulerDialog(TaskItem task) {
    DateTime pickedDate = DateTime.now();
    int selectedHour = DateTime.now().hour.clamp(8, 22);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Zamanlayıcıya Ata'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Tarih:'),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.event, size: 18),
                    label: Text(DateFormat('dd MMM yyyy', 'tr_TR').format(pickedDate)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: pickedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setDlgState(() => pickedDate = d);
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Saat Bloğu:'),
                  const Spacer(),
                  DropdownButton<int>(
                    value: selectedHour,
                    items: List.generate(
                      24,
                      (h) => DropdownMenuItem(
                        value: h,
                        child: Text('${h.toString().padLeft(2, '0')}:00 - ${(h + 1).clamp(0, 23).toString().padLeft(2, '0')}:00'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v != null) setDlgState(() => selectedHour = v);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.xiaomiOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await this
                    .context
                    .read<SchedulerViewModel>()
                    .assignTaskToHour(task, selectedHour, date: pickedDate);
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? '"${task.title}" saat ${selectedHour.toString().padLeft(2, '0')}:00 bloğuna atandı!'
                          : 'Atama başarısız oldu.'),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Saat Bloğuna Ata'),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        priority,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TasksViewModel>();
    final activeTasks = vm.activeTasks;
    final completedTasks = vm.completedTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görevler & Checklist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.loadTasks,
          ),
        ],
      ),
      body: Column(
        children: [
          // Priority filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _filterChip(vm, null, 'Tümü'),
                const SizedBox(width: 8),
                _filterChip(vm, 'Yüksek', 'Yüksek Öncelik'),
                const SizedBox(width: 8),
                _filterChip(vm, 'Orta', 'Orta'),
                const SizedBox(width: 8),
                _filterChip(vm, 'Düşük', 'Düşük'),
              ],
            ),
          ),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.xiaomiOrange))
                : RefreshIndicator(
                    color: AppTheme.xiaomiOrange,
                    onRefresh: vm.loadTasks,
                    child: CustomScrollView(
                      slivers: [
                        if (activeTasks.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                              child: Row(
                                children: [
                                  const Text(
                                    'Devam Eden Görevler',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Sürükleyerek sıralayın',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // ReorderableListView via SliverReorderableList for drag-and-drop task ordering
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            sliver: SliverReorderableList(
                              itemCount: activeTasks.length,
                              onReorderItem: vm.reorderActiveTasks,
                              itemBuilder: (context, index) {
                                final task = activeTasks[index];
                                return ReorderableDelayedDragStartListener(
                                  key: ValueKey('task_${task.id}'),
                                  index: index,
                                  child: _buildTaskTile(task, vm, index: index, showDragHandle: true),
                                );
                              },
                            ),
                          ),
                        ],
                        if (completedTasks.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                              child: Text(
                                'Tamamlananlar (${completedTasks.length})',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildTaskTile(completedTasks[index], vm),
                                childCount: completedTasks.length,
                              ),
                            ),
                          ),
                        ],
                        if (activeTasks.isEmpty && completedTasks.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Harika! Bekleyen görev yok.',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 88)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'tasks_fab',
        onPressed: () => _showTaskDialog(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _filterChip(TasksViewModel vm, String? value, String label) {
    final selected = vm.priorityFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.black87)),
      selected: selected,
      selectedColor: AppTheme.xiaomiOrange,
      backgroundColor: Colors.white,
      onSelected: (_) => vm.setPriorityFilter(value),
    );
  }

  Widget _buildTaskTile(
    TaskItem task,
    TasksViewModel vm, {
    int? index,
    bool showDragHandle = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.only(left: 8, right: 6),
            leading: Checkbox(
              value: task.isCompleted,
              activeColor: AppTheme.xiaomiOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              onChanged: (_) => vm.toggleComplete(task.id),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? Colors.grey : Colors.black87,
              ),
            ),
            subtitle: task.dueDate != null
                ? Text(
                    DateFormat('dd MMM yyyy', 'tr_TR').format(task.dueDate!.toLocal()),
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPriorityBadge(task.priority),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                  onSelected: (action) {
                    if (action == 'subtask') {
                      _showTaskDialog(parentId: task.id);
                    } else if (action == 'schedule') {
                      _showAssignToSchedulerDialog(task);
                    } else if (action == 'edit') {
                      _showTaskDialog(existing: task);
                    } else if (action == 'delete') {
                      vm.deleteTask(task.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'schedule',
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 18, color: AppTheme.xiaomiOrange),
                          SizedBox(width: 8),
                          Text('Zamanlayıcıya Ata'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'subtask',
                      child: Row(
                        children: [
                          Icon(Icons.subdirectory_arrow_right, size: 18),
                          SizedBox(width: 8),
                          Text('Alt Görev Ekle'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Sil', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (showDragHandle && index != null)
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                    ),
                  ),
              ],
            ),
          ),
          if (task.subtasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 12, bottom: 8),
              child: Column(
                children: task.subtasks.map((sub) {
                  return Row(
                    children: [
                      Checkbox(
                        value: sub.isCompleted,
                        activeColor: AppTheme.xiaomiOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (_) => vm.toggleComplete(sub.id),
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
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () => vm.deleteTask(sub.id),
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
