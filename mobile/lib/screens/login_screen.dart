import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'user@xiaomi.com');
  final _passCtrl = TextEditingController(text: 'User123!');
  final _nameCtrl = TextEditingController();

  bool _isRegister = false;
  bool _obscurePassword = true;
  String _selectedRole = 'User';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    if (_isRegister) {
      await auth.register(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passCtrl.text,
        _selectedRole,
      );
    } else {
      await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    }
  }

  void _showServerDialog() {
    final auth = context.read<AuthViewModel>();
    final urlCtrl = TextEditingController(text: auth.apiBaseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.dns_outlined, color: AppTheme.xiaomiOrange),
            SizedBox(width: 8),
            Text('API Sunucu Adresi', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fiziksel telefon kullanıyorsanız bilgisayarınızın yerel Wi-Fi IP adresini girin (örn: http://192.168.1.35:5186/api).',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Web API Base URL',
                hintText: 'http://192.168.1.XX:5186/api',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.xiaomiOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final ok = await auth.updateApiUrl(urlCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Sunucuya başarıyla bağlanıldı!'
                        : 'Adres kaydedildi ancak sunucuya ulaşılamadı.'),
                    backgroundColor: ok ? Colors.green : Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Kaydet ve Test Et'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: _showServerDialog,
            icon: Icon(
              auth.isServerOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              size: 18,
              color: auth.isServerOnline ? Colors.green : Colors.orange,
            ),
            label: Text(
              auth.isServerOnline ? 'API Bağlı' : 'API Ayarla',
              style: TextStyle(
                fontSize: 12,
                color: auth.isServerOnline ? Colors.green : Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppTheme.xiaomiOrange,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.xiaomiOrange.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.note_alt, size: 42, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Xiaomi Notes & Scheduler',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRegister
                        ? 'Yeni hesap oluşturun (JWT Kimlik Doğrulama)'
                        : 'ASP.NET Core Web API ile Güvenli Giriş',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (auth.error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        auth.error!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 12.5),
                      ),
                    ),
                  if (_isRegister) ...[
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (!_isRegister) return null;
                        if (v == null || v.trim().length < 2) {
                          return 'Ad Soyad en az 2 karakter olmalıdır.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-posta Adresi',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final email = v?.trim() ?? '';
                      if (email.isEmpty) return 'E-posta adresi zorunludur.';
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(email)) {
                        return 'Geçerli bir e-posta adresi giriniz.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Şifre zorunludur.';
                      if (v.length < 6) return 'Şifre en az 6 karakter olmalıdır.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_isRegister)
                    Row(
                      children: [
                        const Text('Hesap Rolü:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        ChoiceChip(
                          label: const Text('Kullanıcı'),
                          selected: _selectedRole == 'User',
                          selectedColor: AppTheme.xiaomiOrange.withValues(alpha: 0.2),
                          onSelected: (_) => setState(() => _selectedRole = 'User'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Yönetici'),
                          selected: _selectedRole == 'Admin',
                          selectedColor: AppTheme.xiaomiOrange.withValues(alpha: 0.2),
                          onSelected: (_) => setState(() => _selectedRole = 'Admin'),
                        ),
                      ],
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.person, size: 16, color: AppTheme.xiaomiOrange),
                          label: const Text('Demo Kullanıcı', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            _emailCtrl.text = 'user@xiaomi.com';
                            _passCtrl.text = 'User123!';
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.admin_panel_settings, size: 16, color: Colors.deepPurple),
                          label: const Text('Demo Yönetici (Admin)', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            _emailCtrl.text = 'admin@xiaomi.com';
                            _passCtrl.text = 'Admin123!';
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.xiaomiOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              _isRegister ? 'Kayıt Ol ve Başla' : 'Giriş Yap (JWT)',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      auth.clearError();
                      setState(() => _isRegister = !_isRegister);
                    },
                    child: Text(
                      _isRegister
                          ? 'Zaten hesabınız var mı? Giriş yapın'
                          : 'Hesabınız yok mu? Yeni hesap oluşturun',
                      style: const TextStyle(color: AppTheme.xiaomiOrange),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
