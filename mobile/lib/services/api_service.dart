import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/category.dart';
import '../models/note.dart';
import '../models/schedule_item.dart';
import '../models/task_item.dart';
import '../models/user.dart';
import 'storage_service.dart';

class ApiResult<T> {
  final T? data;
  final String? error;
  bool get isSuccess => error == null && data != null;

  ApiResult.success(this.data) : error = null;
  ApiResult.failure(this.error) : data = null;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final StorageService _storage = StorageService();
  late Dio _dio;
  String? _customBaseUrl;
  String? _authToken;
  UserItem? currentUser;
  bool _initialized = false;

  String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:5186/api';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5186/api'
        : 'http://localhost:5186/api';
  }

  String get baseUrl => (_customBaseUrl != null && _customBaseUrl!.isNotEmpty)
      ? _customBaseUrl!
      : defaultBaseUrl;

  /// Root host without `/api` suffix for static uploaded audio files
  String get hostRoot {
    final url = baseUrl;
    if (url.endsWith('/api')) {
      return url.substring(0, url.length - 4);
    }
    return url;
  }

  Future<void> init() async {
    if (_initialized) return;
    _customBaseUrl = await _storage.getCustomApiUrl();
    _authToken = await _storage.getToken();
    currentUser = await _storage.getSavedUser();

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = baseUrl;
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          handler.next(options);
        },
      ),
    );

    _initialized = true;
  }

  Future<void> setBaseUrl(String rawUrl) async {
    var cleaned = rawUrl.trim();
    if (cleaned.isEmpty) {
      _customBaseUrl = null;
      await _storage.saveCustomApiUrl(null);
      _dio.options.baseUrl = baseUrl;
      return;
    }
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'http://$cleaned';
    }
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    if (!cleaned.endsWith('/api')) {
      cleaned = '$cleaned/api';
    }
    _customBaseUrl = cleaned;
    await _storage.saveCustomApiUrl(cleaned);
    _dio.options.baseUrl = cleaned;
  }

  Future<bool> testConnection() async {
    try {
      final res = await _dio.get('/health');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String resolveMediaUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    if (pathOrUrl.startsWith('/')) {
      return '$hostRoot$pathOrUrl';
    }
    return pathOrUrl;
  }

  String _extractError(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        if (data['message'] != null) return data['message'].toString();
        if (data['errors'] is Map) {
          final errs = (data['errors'] as Map).values
              .expand((v) => v is List ? v : [v])
              .map((v) => v.toString())
              .join('\n');
          if (errs.isNotEmpty) return errs;
        }
        if (data['title'] != null) return data['title'].toString();
      }
      if (e.response?.statusCode == 401) {
        return 'Oturum geçersiz veya yetkisiz erişim (401).';
      }
      if (e.response?.statusCode == 403) {
        return 'Bu işlem için Yönetici (Admin) yetkisi gereklidir (403).';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Web API sunucusuna bağlanılamadı ($baseUrl).\nLütfen API sunucusunun çalıştığından ve IP adresinin doğru olduğundan emin olun.';
      }
    }
    return fallback;
  }

  // ==================== AUTH ====================

  Future<ApiResult<UserItem>> login(String email, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });
      final user = UserItem.fromJson(Map<String, dynamic>.from(res.data));
      currentUser = user;
      _authToken = user.token;
      await _storage.saveSession(user);
      return ApiResult.success(user);
    } catch (e) {
      return ApiResult.failure(_extractError(e, 'Giriş yapılamadı.'));
    }
  }

  Future<ApiResult<UserItem>> register(
      String fullName, String email, String password, String role) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'role': role,
      });
      final user = UserItem.fromJson(Map<String, dynamic>.from(res.data));
      currentUser = user;
      _authToken = user.token;
      await _storage.saveSession(user);
      return ApiResult.success(user);
    } catch (e) {
      return ApiResult.failure(_extractError(e, 'Kayıt başarısız oldu.'));
    }
  }

  Future<UserItem?> validateSavedSession() async {
    if (_authToken == null || _authToken!.isEmpty) return null;
    try {
      final res = await _dio.get('/auth/me');
      if (res.statusCode == 200 && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data);
        data['token'] = _authToken;
        currentUser = UserItem.fromJson(data);
        await _storage.saveSession(currentUser!);
        return currentUser;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await logout();
        return null;
      }
      // Keep cached user if only temporarily offline
      return currentUser;
    } catch (_) {
      return currentUser;
    }
    return currentUser;
  }

  Future<void> logout() async {
    currentUser = null;
    _authToken = null;
    _dio.options.headers.remove('Authorization');
    await _storage.clearSession();
  }

  // ==================== NOTES CRUD ====================

  Future<List<Note>> getNotes({String? search, int? categoryId, bool? isVault}) async {
    final params = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
    if (categoryId != null) params['categoryId'] = categoryId;
    if (isVault != null) params['isVault'] = isVault;

    final res = await _dio.get('/notes', queryParameters: params);
    return (res.data as List).map((n) => Note.fromJson(Map<String, dynamic>.from(n))).toList();
  }

  Future<Note> saveNote(Note note) async {
    final payload = {
      'title': note.title,
      'contentJson': note.contentJson,
      'categoryId': note.categoryId,
      'colorHex': note.colorHex,
      'isPinned': note.isPinned,
      'isVault': note.isVault,
      'mindMapData': note.mindMapData,
      'audioUrl': note.audioUrl,
      'drawingData': note.drawingData,
    };

    if (note.id == 0) {
      final res = await _dio.post('/notes', data: payload);
      return Note.fromJson(Map<String, dynamic>.from(res.data));
    } else {
      final res = await _dio.put('/notes/${note.id}', data: payload);
      return Note.fromJson(Map<String, dynamic>.from(res.data));
    }
  }

  Future<void> deleteNote(int id) async {
    await _dio.delete('/notes/$id');
  }

  Future<Note> togglePinNote(int id) async {
    final res = await _dio.patch('/notes/$id/toggle-pin');
    return Note.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<Note> toggleVaultNote(int id) async {
    final res = await _dio.patch('/notes/$id/toggle-vault');
    return Note.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<String?> uploadAudio(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });
      final res = await _dio.post('/notes/upload-audio', data: formData);
      if (res.statusCode == 200 && res.data is Map) {
        return res.data['audioUrl']?.toString();
      }
    } catch (_) {}
    return null;
  }

  // ==================== CATEGORIES CRUD ====================

  Future<List<CategoryItem>> getCategories() async {
    final res = await _dio.get('/categories');
    return (res.data as List)
        .map((c) => CategoryItem.fromJson(Map<String, dynamic>.from(c)))
        .toList();
  }

  Future<CategoryItem> createCategory(String name, {String colorCode = '#FF6900', String icon = 'folder'}) async {
    final res = await _dio.post('/categories', data: {
      'name': name.trim(),
      'colorCode': colorCode,
      'icon': icon,
    });
    return CategoryItem.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<CategoryItem> updateCategory(int id, String name, {String colorCode = '#FF6900', String icon = 'folder'}) async {
    final res = await _dio.put('/categories/$id', data: {
      'name': name.trim(),
      'colorCode': colorCode,
      'icon': icon,
    });
    return CategoryItem.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<void> deleteCategory(int id) async {
    await _dio.delete('/categories/$id');
  }

  // ==================== TASKS CRUD ====================

  Future<List<TaskItem>> getTasks() async {
    final res = await _dio.get('/tasks');
    return (res.data as List)
        .map((t) => TaskItem.fromJson(Map<String, dynamic>.from(t)))
        .toList();
  }

  Future<TaskItem> createTask(
    String title, {
    String priority = 'Orta',
    DateTime? dueDate,
    int? parentId,
    int? noteId,
  }) async {
    final res = await _dio.post('/tasks', data: {
      'title': title.trim(),
      'priority': priority,
      'dueDate': dueDate?.toUtc().toIso8601String(),
      'parentId': parentId,
      'noteId': noteId,
    });
    return TaskItem.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<TaskItem> updateTask(TaskItem task) async {
    final res = await _dio.put('/tasks/${task.id}', data: {
      'title': task.title.trim(),
      'isCompleted': task.isCompleted,
      'priority': task.priority,
      'dueDate': task.dueDate?.toUtc().toIso8601String(),
      'noteId': task.noteId,
      'parentId': task.parentId,
      'orderIndex': task.orderIndex,
    });
    return TaskItem.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<void> toggleTaskComplete(int id) async {
    await _dio.patch('/tasks/$id/toggle-complete');
  }

  Future<void> reorderTasks(List<TaskItem> orderedTasks) async {
    final items = <Map<String, dynamic>>[];
    for (int i = 0; i < orderedTasks.length; i++) {
      items.add({
        'id': orderedTasks[i].id,
        'orderIndex': i,
        'parentId': orderedTasks[i].parentId,
      });
    }
    await _dio.patch('/tasks/reorder', data: {'items': items});
  }

  Future<void> deleteTask(int id) async {
    await _dio.delete('/tasks/$id');
  }

  // ==================== SCHEDULES CRUD ====================

  Future<List<ScheduleItem>> getSchedules({DateTime? date, int? year, int? month}) async {
    final params = <String, dynamic>{};
    if (date != null) {
      params['date'] =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    if (year != null) params['year'] = year;
    if (month != null) params['month'] = month;

    final res = await _dio.get('/schedules', queryParameters: params);
    return (res.data as List)
        .map((s) => ScheduleItem.fromJson(Map<String, dynamic>.from(s)))
        .toList();
  }

  Future<ScheduleItem> createSchedule(ScheduleItem schedule) async {
    final res = await _dio.post('/schedules', data: schedule.toRequestJson());
    return ScheduleItem.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<ScheduleItem> updateSchedule(ScheduleItem schedule) async {
    final res = await _dio.put('/schedules/${schedule.id}', data: schedule.toRequestJson());
    return ScheduleItem.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<void> deleteSchedule(int id) async {
    await _dio.delete('/schedules/$id');
  }

  // ==================== ADMIN & USERS CRUD ====================

  Future<Map<String, dynamic>> getAdminStats() async {
    final res = await _dio.get('/admin/stats');
    return Map<String, dynamic>.from(res.data);
  }

  Future<List<UserItem>> getAdminUsers() async {
    final res = await _dio.get('/users');
    return (res.data as List)
        .map((u) => UserItem.fromJson(Map<String, dynamic>.from(u)))
        .toList();
  }

  Future<UserItem> createUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final res = await _dio.post('/users', data: {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'password': password,
      'role': role,
      'isActive': true,
    });
    return UserItem.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<void> toggleUserStatus(int userId) async {
    await _dio.post('/admin/users/$userId/toggle-status');
  }

  Future<void> changeUserRole(int userId, String newRole) async {
    await _dio.patch('/admin/users/$userId/role', data: {'role': newRole});
  }

  Future<void> deleteUser(int userId) async {
    await _dio.delete('/users/$userId');
  }

  Future<List<Map<String, dynamic>>> getAdminNotes() async {
    final res = await _dio.get('/admin/notes');
    return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> deleteAdminNote(int noteId) async {
    await _dio.delete('/admin/notes/$noteId');
  }

  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    final res = await _dio.get('/admin/audit-logs');
    return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
