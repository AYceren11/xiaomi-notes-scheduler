import 'package:flutter/material.dart';

class AppTheme {
  static const Color xiaomiOrange = Color(0xFFFF6900);
  static const Color backgroundLight = Color(0xFFF7F7F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  static const List<Color> noteColors = [
    Color(0xFFFFF9E6), // Xiaomi Warm Yellow
    Color(0xFFE3F2FD), // Soft Blue
    Color(0xFFE8F5E9), // Soft Green
    Color(0xFFFCE4EC), // Soft Pink
    Color(0xFFFFF3E0), // Soft Orange
    Color(0xFFEDE7F6), // Soft Purple
    Color(0xFFFFFFFF), // Pure White
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: xiaomiOrange,
        primary: xiaomiOrange,
        surface: surfaceLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.04), width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: xiaomiOrange,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: CircleBorder(),
      ),
    );
  }
}
