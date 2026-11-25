import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../viewmodels/scheduler_viewmodel.dart';
import '../viewmodels/tasks_viewmodel.dart';
import 'admin_screen.dart';
import 'notes_screen.dart';
import 'scheduler_screen.dart';
import 'tasks_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesViewModel>().loadAll();
      context.read<TasksViewModel>().loadTasks();
      context.read<SchedulerViewModel>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthViewModel>().isAdmin;

    final screens = <Widget>[
      const NotesScreen(),
      const TasksScreen(),
      const SchedulerScreen(),
      if (isAdmin) const AdminScreen(),
    ];

    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.note_alt_outlined),
        activeIcon: Icon(Icons.note_alt),
        label: 'Notlar',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.check_box_outlined),
        activeIcon: Icon(Icons.check_box),
        label: 'Görevler',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_outlined),
        activeIcon: Icon(Icons.calendar_month),
        label: 'Zamanlayıcı',
      ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings),
          label: 'Yönetici',
        ),
    ];

    final safeIndex = _currentIndex >= screens.length ? 0 : _currentIndex;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.8)),
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.xiaomiOrange,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: navItems,
        ),
      ),
    );
  }
}
