import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../models/task_item.dart';
import '../models/category.dart';
import '../models/user.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;

  // Base URL: 10.0.2.2 is host loopback for Android Emulator, localhost for Windows/Web
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5000/api'
        : 'http://localhost:5000/api';
  }

  UserItem? currentUser;
  String? _authToken;

  // Local state cache for offline/standalone execution
  List<Note> _localNotes = [];
  List<TaskItem> _localTasks = [];
  List<CategoryItem> _localCategories = [];

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _seedInitialData();
  }

  void _seedInitialData() {
    _localCategories = [
      CategoryItem(id: 1, userId: 1, name: 'Önemli', colorCode: '#FF6900', icon: 'star'),
      CategoryItem(id: 2, userId: 1, name: 'İş', colorCode: '#2196F3', icon: 'work'),
      CategoryItem(id: 3, userId: 1, name: 'Kişisel', colorCode: '#4CAF50', icon: 'person'),
      CategoryItem(id: 4, userId: 1, name: 'Dersler', colorCode: '#9C27B0', icon: 'book'),
    ];

    _localNotes = [
      Note(
        id: 1,
        userId: 1,
        categoryId: 1,
        title: '⚡ Xiaomi Hızlı Not & Zamanlayıcı',
        contentJson: '• Sol kenardaki turuncu çubuktan diğer uygulamaların üzerinde hızlıca not ve görev ekleyebilirsiniz.\n• Görevler tamamlandığında silinmez, üstü çizili kalır.\n• Görevlerin sırasını değiştirebilir ve bir görevi başka bir görevin altına alt görev olarak taşıyabilirsiniz.\n• 24 saatlik dikey zaman matrisinde görevlerinizi saatlere sürükleyebilirsiniz.',
        colorHex: '#FFF9E6',
        isPinned: true,
        isVault: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      Note(
        id: 2,
        userId: 1,
        categoryId: 4,
        title: 'BLM4587 Dönem Projesi Mimarisi',
        contentJson: 'Backend: ASP.NET Core 8 Web API + PostgreSQL + EF Core Code-First.\nFrontend: Flutter (Dart) + Dio.\nKimlik Doğrulama: JWT Token tabanlı (Admin ve User rolleri).\nÖzellikler: Zengin metin düzenleyici, 24 saatlik ajanda, şifreli kasa.',
        colorHex: '#E3F2FD',
        isPinned: true,
        isVault: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Note(
        id: 3,
        userId: 1,
        categoryId: 3,
        title: 'Kitap & Makale Önerileri',
        contentJson: '1. Clean Architecture - Robert C. Martin\n2. Flutter Apprentice\n3. Microservices in .NET Core\n4. Database System Concepts',
        colorHex: '#E8F5E9',
        isPinned: false,
        isVault: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    _localTasks = [
      TaskItem(
        id: 1,
        userId: 1,
        title: 'Proje mimarisinin kurulması ve Web API uç noktaları',
        isCompleted: true,
        priority: 'Yüksek',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        completedAt: DateTime.now(),
      ),
      TaskItem(
        id: 2,
        userId: 1,
        title: 'Flutter arayüz tasarımı ve Xiaomi MIUI teması',
        isCompleted: false,
        priority: 'Yüksek',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now(),
        subtasks: [
          TaskItem(
            id: 21,
            userId: 1,
            parentId: 2,
            title: 'Not kartları ve Masonry grid düzeni',
            isCompleted: true,
            createdAt: DateTime.now(),
          ),
          TaskItem(
            id: 22,
            userId: 1,
            parentId: 2,
            title: '24 saatlik zamanlayıcı matrisi',
            isCompleted: false,
            createdAt: DateTime.now(),
          ),
        ],
      ),
      TaskItem(
        id: 3,
        userId: 1,
        title: 'Haftalık Alışveriş Listesi',
        isCompleted: false,
        priority: 'Orta',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
      ),
    ];
  }

  // --- Auth ---
  Future<UserItem?> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      if (response.statusCode == 200) {
        currentUser = UserItem.fromJson(response.data);
        _authToken = currentUser?.token;
        _dio.options.headers['Authorization'] = 'Bearer $_authToken';
        return currentUser;
      }
    } catch (_) {
      currentUser = UserItem(
        id: email.contains('admin') ? 1 : 2,
        fullName: email.contains('admin') ? 'Sistem Yöneticisi' : 'Ayşe Ceren Şenel',
        email: email,
        role: email.contains('admin') ? 'Admin' : 'User',
        token: 'mock-jwt-token',
      );
      return currentUser;
    }
    return null;
  }

  Future<UserItem?> register(String fullName, String email, String password, String role) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
      });
      if (response.statusCode == 200) {
        currentUser = UserItem.fromJson(response.data);
        _authToken = currentUser?.token;
        _dio.options.headers['Authorization'] = 'Bearer $_authToken';
        return currentUser;
      }
    } catch (_) {
      currentUser = UserItem(
        id: 2,
        fullName: fullName,
        email: email,
        role: role,
        token: 'mock-jwt-token',
      );
      return currentUser;
    }
    return null;
  }

  // --- Notes CRUD ---
  Future<List<Note>> getNotes({String? search, int? categoryId}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categoryId != null) queryParams['categoryId'] = categoryId;

      final response = await _dio.get('/notes', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data is List) {
        _localNotes = (response.data as List).map((n) => Note.fromJson(n)).toList();
        return _localNotes;
      }
    } catch (_) {
      // Fallback to cached notes
    }

    var list = List<Note>.from(_localNotes);
    if (categoryId != null) {
      list = list.where((n) => n.categoryId == categoryId).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((n) => n.title.toLowerCase().contains(q) || n.contentJson.toLowerCase().contains(q)).toList();
    }
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  Future<Note> saveNote(Note note) async {
    if (note.id == 0) {
      try {
        final res = await _dio.post('/notes', data: {
          'title': note.title,
          'contentJson': note.contentJson,
          'categoryId': note.categoryId,
          'colorHex': note.colorHex,
          'isPinned': note.isPinned,
          'isVault': note.isVault,
        });
        if (res.statusCode == 201 || res.statusCode == 200) {
          final created = Note.fromJson(res.data);
          _localNotes.insert(0, created);
          return created;
        }
      } catch (_) {}

      final newNote = note.copyWith(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _localNotes.insert(0, newNote);
      return newNote;
    } else {
      try {
        await _dio.put('/notes/${note.id}', data: {
          'title': note.title,
          'contentJson': note.contentJson,
          'categoryId': note.categoryId,
          'colorHex': note.colorHex,
          'isPinned': note.isPinned,
          'isVault': note.isVault,
        });
      } catch (_) {}

      final idx = _localNotes.indexWhere((n) => n.id == note.id);
      final updated = note.copyWith(updatedAt: DateTime.now());
      if (idx != -1) {
        _localNotes[idx] = updated;
      }
      return updated;
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _dio.delete('/notes/$id');
    } catch (_) {}
    _localNotes.removeWhere((n) => n.id == id);
  }

  Future<void> togglePinNote(int id) async {
    try {
      await _dio.patch('/notes/$id/toggle-pin');
    } catch (_) {}
    final idx = _localNotes.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _localNotes[idx] = _localNotes[idx].copyWith(
        isPinned: !_localNotes[idx].isPinned,
        updatedAt: DateTime.now(),
      );
    }
  }

  // --- Tasks CRUD ---
  Future<List<TaskItem>> getTasks() async {
    try {
      final response = await _dio.get('/tasks');
      if (response.statusCode == 200 && response.data is List) {
        _localTasks = (response.data as List).map((t) => TaskItem.fromJson(t)).toList();
        return _localTasks;
      }
    } catch (_) {}
    return _localTasks;
  }

  Future<TaskItem> createTask(String title, {String priority = 'Orta', DateTime? dueDate, int? parentId}) async {
    try {
      final res = await _dio.post('/tasks', data: {
        'title': title,
        'priority': priority,
        'dueDate': dueDate?.toIso8601String(),
        'parentId': parentId,
      });
      if (res.statusCode == 201 || res.statusCode == 200) {
        final t = TaskItem.fromJson(res.data);
        _localTasks.add(t);
        return t;
      }
    } catch (_) {}

    final newTask = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      userId: 1,
      title: title,
      priority: priority,
      dueDate: dueDate,
      parentId: parentId,
      createdAt: DateTime.now(),
    );
    if (parentId != null) {
      final pIdx = _localTasks.indexWhere((t) => t.id == parentId);
      if (pIdx != -1) {
        final p = _localTasks[pIdx];
        _localTasks[pIdx] = p.copyWith(subtasks: [...p.subtasks, newTask]);
      }
    } else {
      _localTasks.add(newTask);
    }
    return newTask;
  }

  Future<void> toggleTaskComplete(int id) async {
    try {
      await _dio.patch('/tasks/$id/toggle-complete');
    } catch (_) {}

    for (int i = 0; i < _localTasks.length; i++) {
      if (_localTasks[i].id == id) {
        final cur = _localTasks[i];
        _localTasks[i] = cur.copyWith(isCompleted: !cur.isCompleted);
        return;
      }
      for (int j = 0; j < _localTasks[i].subtasks.length; j++) {
        if (_localTasks[i].subtasks[j].id == id) {
          final sub = _localTasks[i].subtasks[j];
          _localTasks[i].subtasks[j] = sub.copyWith(isCompleted: !sub.isCompleted);
          return;
        }
      }
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _dio.delete('/tasks/$id');
    } catch (_) {}
    _localTasks.removeWhere((t) => t.id == id);
  }

  // --- Categories ---
  Future<List<CategoryItem>> getCategories() async {
    try {
      final res = await _dio.get('/categories');
      if (res.statusCode == 200 && res.data is List) {
        _localCategories = (res.data as List).map((c) => CategoryItem.fromJson(c)).toList();
        return _localCategories;
      }
    } catch (_) {}
    return _localCategories;
  }

  // --- Admin ---
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final res = await _dio.get('/admin/stats');
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(res.data);
      }
    } catch (_) {}

    return {
      'totalUsers': 2,
      'totalNotes': _localNotes.length,
      'totalTasks': _localTasks.length,
      'completedTasks': _localTasks.where((t) => t.isCompleted).length,
      'totalCategories': _localCategories.length,
      'recentLogs': [
        {'action': 'SYSTEM_INITIALIZED', 'entityName': 'Database', 'timestamp': DateTime.now().toIso8601String(), 'ipAddress': '127.0.0.1'},
        {'action': 'LOGIN_SUCCESS', 'entityName': 'User', 'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(), 'ipAddress': '127.0.0.1'},
      ]
    };
  }
}
