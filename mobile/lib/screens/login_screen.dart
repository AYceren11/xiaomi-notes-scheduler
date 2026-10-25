import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'user@xiaomi.com');
  final _passCtrl = TextEditingController(text: 'User123!');
  final _nameCtrl = TextEditingController(text: 'Ayşe Ceren Şenel');
  final ApiService _api = ApiService();

  bool _isRegister = false;
  String _selectedRole = 'User';
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen e-posta ve şifre giriniz.';
        _isLoading = false;
      });
      return;
    }

    if (_isRegister) {
      final user = await _api.register(_nameCtrl.text.trim(), email, pass, _selectedRole);
      if (user != null) {
        widget.onLoginSuccess();
      } else {
        setState(() => _errorMessage = 'Kayıt başarısız oldu.');
      }
    } else {
      final user = await _api.login(email, pass);
      if (user != null) {
        widget.onLoginSuccess();
      } else {
        setState(() => _errorMessage = 'Giriş yapılamadı.');
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.xiaomiOrange,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.xiaomiOrange.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.note_alt, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Xiaomi Notes & Scheduler',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(
                _isRegister ? 'Yeni hesap oluşturun' : 'Web API ile Güvenli Giriş',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              if (_isRegister) ...[
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'E-posta Adresi',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Rol Seçimi: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  ChoiceChip(
                    label: const Text('Kullanıcı (User)'),
                    selected: _selectedRole == 'User',
                    selectedColor: AppTheme.xiaomiOrange.withValues(alpha: 0.2),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedRole = 'User';
                          _emailCtrl.text = 'user@xiaomi.com';
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Yönetici (Admin)'),
                    selected: _selectedRole == 'Admin',
                    selectedColor: AppTheme.xiaomiOrange.withValues(alpha: 0.2),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedRole = 'Admin';
                          _emailCtrl.text = 'admin@xiaomi.com';
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.xiaomiOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isRegister ? 'Kayıt Ol' : 'Giriş Yap (JWT)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isRegister = !_isRegister),
                child: Text(
                  _isRegister ? 'Zaten hesabınız var mı? Giriş yapın' : 'Hesabınız yok mu? Kaydolun',
                  style: const TextStyle(color: AppTheme.xiaomiOrange),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
