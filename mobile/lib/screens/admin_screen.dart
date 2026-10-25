import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _api.getAdminStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetici Paneli (Admin)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.xiaomiOrange))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Role notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.amber.shade800, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Bu ekran yalnızca "Admin" rolüne sahip kullanıcılara açıktır.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sistem Genel İstatistikleri',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                  children: [
                    _buildStatCard(
                      'Toplam Kullanıcı',
                      '${_stats?['totalUsers'] ?? 2}',
                      Icons.people_alt_outlined,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Kayıtlı Notlar',
                      '${_stats?['totalNotes'] ?? 0}',
                      Icons.note_outlined,
                      AppTheme.xiaomiOrange,
                    ),
                    _buildStatCard(
                      'Toplam Görevler',
                      '${_stats?['totalTasks'] ?? 0}',
                      Icons.check_box_outlined,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      'Tamamlanan',
                      '${_stats?['completedTasks'] ?? 0}',
                      Icons.task_alt,
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sistem Denetim Günlüğü (Audit Logs)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ((_stats?['recentLogs'] as List?) ?? []).length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final log = (_stats?['recentLogs'] as List)[idx];
                      return ListTile(
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFF0F0F0),
                          child: Icon(Icons.history, size: 18, color: Colors.grey),
                        ),
                        title: Text(
                          log['action'] ?? '',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Varlık: ${log['entityName']} • IP: ${log['ipAddress']}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
