import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const _kTokenKey = 'jwt_auth_token';
  static const _kUserKey = 'auth_user_json';
  static const _kVaultPinKey = 'private_vault_pin';
  static const _kApiUrlKey = 'custom_api_base_url';
  static const _kGridModeKey = 'notes_masonry_grid_mode';

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveSession(UserItem user) async {
    try {
      await _secure.write(key: _kTokenKey, value: user.token);
      await _secure.write(key: _kUserKey, value: jsonEncode(user.toJson()));
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTokenKey, user.token);
      await prefs.setString(_kUserKey, jsonEncode(user.toJson()));
    }
  }

  Future<String?> getToken() async {
    try {
      final val = await _secure.read(key: _kTokenKey);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTokenKey);
  }

  Future<UserItem?> getSavedUser() async {
    String? raw;
    try {
      raw = await _secure.read(key: _kUserKey);
    } catch (_) {}
    if (raw == null || raw.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(_kUserKey);
    }
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserItem.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    try {
      await _secure.delete(key: _kTokenKey);
      await _secure.delete(key: _kUserKey);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    await prefs.remove(_kUserKey);
  }

  Future<String> getVaultPin() async {
    try {
      final pin = await _secure.read(key: _kVaultPinKey);
      if (pin != null && pin.isNotEmpty) return pin;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kVaultPinKey) ?? '1234';
  }

  Future<void> saveVaultPin(String pin) async {
    try {
      await _secure.write(key: _kVaultPinKey, value: pin);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVaultPinKey, pin);
  }

  Future<String?> getCustomApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kApiUrlKey);
  }

  Future<void> saveCustomApiUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(_kApiUrlKey);
    } else {
      await prefs.setString(_kApiUrlKey, url.trim());
    }
  }

  Future<bool> getIsMasonryGrid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kGridModeKey) ?? true;
  }

  Future<void> setIsMasonryGrid(bool isGrid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kGridModeKey, isGrid);
  }
}
