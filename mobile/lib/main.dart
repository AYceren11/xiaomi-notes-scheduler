import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  ApiService().init();

  runApp(const XiaomiNotesApp());
}

class XiaomiNotesApp extends StatefulWidget {
  const XiaomiNotesApp({super.key});

  @override
  State<XiaomiNotesApp> createState() => _XiaomiNotesAppState();
}

class _XiaomiNotesAppState extends State<XiaomiNotesApp> {
  bool _isLoggedIn = true; // Set to true by default for immediate smooth demonstration

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xiaomi Notes & Scheduler',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isLoggedIn
          ? MainScreen(onLogout: () => setState(() => _isLoggedIn = false))
          : LoginScreen(onLoginSuccess: () => setState(() => _isLoggedIn = true)),
    );
  }
}
