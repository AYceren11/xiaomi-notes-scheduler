import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../viewmodels/scheduler_viewmodel.dart';
import '../viewmodels/tasks_viewmodel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlCtrl;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: context.read<AuthViewModel>().apiBaseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndTestUrl() async {
    setState(() => _testing = true);
    final ok = await context.read<AuthViewModel>().updateApiUrl(_urlCtrl.text);
    if (mounted) {
      setState(() => _testing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'API bağlantısı doğrulandı!'
              : 'Sunucuya ulaşılamadı. Bilgisayar IP ve port (5186) bilgisini kontrol edin.'),
          backgroundColor: ok ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _logout() async {
    context.read<NotesViewModel>().clear();
    context.read<TasksViewModel>().clear();
    context.read<SchedulerViewModel>().clear();
    await context.read<AuthViewModel>().logout();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar & Hesap')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.xiaomiOrange.withValues(alpha: 0.15),
                    child: Icon(
                      auth.isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: AppTheme.xiaomiOrange,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Kullanıcı',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: auth.isAdmin
                                ? Colors.deepPurple.withValues(alpha: 0.12)
                                : AppTheme.xiaomiOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            auth.isAdmin ? 'Rol: Yönetici (Admin)' : 'Rol: Standart Kullanıcı',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: auth.isAdmin ? Colors.deepPurple : AppTheme.xiaomiOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dns_outlined, color: AppTheme.xiaomiOrange),
                      const SizedBox(width: 8),
                      const Text(
                        'Web API Bağlantı Adresi',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: auth.isServerOnline ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'API Base URL',
                      hintText: 'http://192.168.1.XX:5186/api',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.xiaomiOrange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _testing ? null : _saveAndTestUrl,
                      icon: const Icon(Icons.wifi_tethering),
                      label: Text(_testing ? 'Test Ediliyor...' : 'Kaydet ve Bağlantıyı Test Et'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Oturumu Kapat', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
