import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final List<CategoryItem> categories;

  const NoteEditorScreen({
    super.key,
    this.note,
    required this.categories,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final ApiService _api = ApiService();

  late String _selectedColorHex;
  late bool _isPinned;
  late bool _isVault;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.contentJson ?? '');
    _selectedColorHex = widget.note?.colorHex ?? '#FFF9E6';
    _isPinned = widget.note?.isPinned ?? false;
    _isVault = widget.note?.isVault ?? false;
    _selectedCategoryId = widget.note?.categoryId;
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final noteToSave = Note(
      id: widget.note?.id ?? 0,
      userId: widget.note?.userId ?? 1,
      categoryId: _selectedCategoryId,
      title: title.isEmpty ? 'Başlıksız' : title,
      contentJson: content,
      colorHex: _selectedColorHex,
      isPinned: _isPinned,
      isVault: _isVault,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _api.saveNote(noteToSave);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteNote() async {
    if (widget.note != null && widget.note!.id > 0) {
      await _api.deleteNote(widget.note!.id);
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Not Rengi Seçin',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: AppTheme.noteColors.map((color) {
                  final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                  final isSelected = hex == _selectedColorHex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColorHex = hex);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppTheme.xiaomiOrange : Colors.black12,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 20, color: AppTheme.xiaomiOrange)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(_selectedColorHex);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _saveNote,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? AppTheme.xiaomiOrange : Colors.grey.shade700,
            ),
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: _showColorPicker,
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'vault') {
                setState(() => _isVault = !_isVault);
              } else if (val == 'delete') {
                _deleteNote();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'vault',
                child: Row(
                  children: [
                    Icon(_isVault ? Icons.lock : Icons.lock_open, size: 20),
                    const SizedBox(width: 8),
                    Text(_isVault ? 'Kasadan Çıkar' : 'Gizli Kasaya Ekle'),
                  ],
                ),
              ),
              if (widget.note != null)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Notu Sil', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.xiaomiOrange),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
              decoration: const InputDecoration(
                hintText: 'Başlık',
                hintStyle: TextStyle(color: Colors.black26),
                border: InputBorder.none,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF2E2E2E)),
                decoration: const InputDecoration(
                  hintText: 'Notunuzu yazmaya başlayın...',
                  hintStyle: TextStyle(color: Colors.black26),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
