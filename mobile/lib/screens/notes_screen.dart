import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/miui_folder_chips.dart';
import '../widgets/miui_search_bar.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _api = ApiService();

  List<Note> _notes = [];
  List<CategoryItem> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cats = await _api.getCategories();
    final notes = await _api.getNotes(
      search: _searchController.text,
      categoryId: _selectedCategoryId,
    );
    if (mounted) {
      setState(() {
        _categories = cats;
        _notes = notes;
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(int? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _loadData();
  }

  void _onSearch(String query) {
    _loadData();
  }

  Future<void> _openEditor([Note? note]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          note: note,
          categories: _categories,
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xiaomi Notlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          MiuiSearchBar(
            controller: _searchController,
            onChanged: _onSearch,
            onClear: () => _onSearch(''),
          ),
          MiuiFolderChips(
            categories: _categories,
            selectedCategoryId: _selectedCategoryId,
            onSelected: _onCategorySelected,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.xiaomiOrange))
                : _notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Henüz not eklenmemiş',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.xiaomiOrange,
                        onRefresh: _loadData,
                        child: ListView.builder(
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            return NoteCard(
                              note: note,
                              onTap: () => _openEditor(note),
                              onTogglePin: () async {
                                await _api.togglePinNote(note.id);
                                _loadData();
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
