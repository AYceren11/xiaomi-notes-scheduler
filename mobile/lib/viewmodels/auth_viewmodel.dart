import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserItem? _user;
  bool _isInitializing = true;
  bool _isLoading = false;
  bool _isServerOnline = false;
  String? _error;

  UserItem? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  bool get isServerOnline => _isServerOnline;
  String? get error => _error;
  String get apiBaseUrl => _api.baseUrl;

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    await _api.init();
    _isServerOnline = await _api.testConnection();
    _user = await _api.validateSavedSession();

    _isInitializing = false;
    notifyListeners();
  }

  Future<bool> checkServerConnection() async {
    _isServerOnline = await _api.testConnection();
    notifyListeners();
    return _isServerOnline;
  }

  Future<bool> updateApiUrl(String url) async {
    await _api.setBaseUrl(url);
    _isServerOnline = await _api.testConnection();
    notifyListeners();
    return _isServerOnline;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final res = await _api.login(email, password);
    _isLoading = false;

    if (res.isSuccess) {
      _user = res.data;
      _isServerOnline = true;
      notifyListeners();
      return true;
    } else {
      _error = res.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String fullName, String email, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final res = await _api.register(fullName, email, password, role);
    _isLoading = false;

    if (res.isSuccess) {
      _user = res.data;
      _isServerOnline = true;
      notifyListeners();
      return true;
    } else {
      _error = res.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
