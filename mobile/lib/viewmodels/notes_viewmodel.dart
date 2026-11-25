import 'dart:io';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class NotesViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  List<Note> _notes = [];
  List<Note> _vaultNotes = [];
  List<CategoryItem> _categories = [];
  int? _selectedCategoryId;
  String _searchQuery = '';
  bool _isMasonryGrid = true;
  bool _isLoading = false;
  String? _error;

  List<Note> get notes => _notes;
  List<Note> get vaultNotes => _vaultNotes;
  List<CategoryItem> get categories => _categories;
  int? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isMasonryGrid => _isMasonryGrid;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _isMasonryGrid = await _storage.getIsMasonryGrid();

    try {
      final results = await Future.wait([
        _api.getCategories(),
        _api.getNotes(
          search: _searchQuery,
          categoryId: _selectedCategoryId,
          isVault: false,
        ),
      ]);
      _categories = results[0] as List<CategoryItem>;
      _notes = results[1] as List<Note>;
    } catch (e) {
      _error = 'Notlar yüklenemedi. API bağlantısını kontrol edin.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadVaultNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vaultNotes = await _api.getNotes(isVault: true);
    } catch (_) {
      _error = 'Kasa notları yüklenemedi.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleViewMode() async {
    _isMasonryGrid = !_isMasonryGrid;
    await _storage.setIsMasonryGrid(_isMasonryGrid);
    notifyListeners();
  }

  Future<void> selectCategory(int? categoryId) async {
    _selectedCategoryId = categoryId;
    await loadAll();
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    await loadAll();
  }

  Future<Note?> saveNote(Note note) async {
    try {
      final saved = await _api.saveNote(note);
      await loadAll();
      if (note.isVault) {
        await loadVaultNotes();
      }
      return saved;
    } catch (_) {
      _error = 'Not kaydedilemedi.';
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteNote(int id, {bool fromVault = false}) async {
    try {
      await _api.deleteNote(id);
      if (fromVault) {
        await loadVaultNotes();
      } else {
        await loadAll();
      }
    } catch (_) {
      _error = 'Not silinemedi.';
      notifyListeners();
    }
  }

  Future<void> togglePin(int id) async {
    try {
      await _api.togglePinNote(id);
      await loadAll();
    } catch (_) {}
  }

  Future<void> toggleVault(int id) async {
    try {
      await _api.toggleVaultNote(id);
      await loadAll();
      await loadVaultNotes();
    } catch (_) {}
  }

  Future<String?> uploadVoiceFile(File file) async {
    return await _api.uploadAudio(file);
  }

  // Category CRUD
  Future<bool> addCategory(String name, String colorCode, String icon) async {
    try {
      await _api.createCategory(name, colorCode: colorCode, icon: icon);
      await loadAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> editCategory(int id, String name, String colorCode, String icon) async {
    try {
      await _api.updateCategory(id, name, colorCode: colorCode, icon: icon);
      await loadAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeCategory(int id) async {
    try {
      await _api.deleteCategory(id);
      if (_selectedCategoryId == id) _selectedCategoryId = null;
      await loadAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  void clear() {
    _notes = [];
    _vaultNotes = [];
    _categories = [];
    _selectedCategoryId = null;
    _searchQuery = '';
    notifyListeners();
  }
}
