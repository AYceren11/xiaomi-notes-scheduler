import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../models/category.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../viewmodels/tasks_viewmodel.dart';
import 'drawing_screen.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final List<CategoryItem> categories;
  final bool defaultVault;

  const NoteEditorScreen({
    super.key,
    this.note,
    required this.categories,
    this.defaultVault = false,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final quill.QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  // Voice recording & playback
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  late String _selectedColorHex;
  late bool _isPinned;
  late bool _isVault;
  int? _selectedCategoryId;
  String? _mindMapData;
  String? _audioUrl;
  String? _drawingData;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _selectedColorHex = widget.note?.colorHex ?? '#FFF9E6';
    _isPinned = widget.note?.isPinned ?? false;
    _isVault = widget.note?.isVault ?? widget.defaultVault;
    _selectedCategoryId = widget.note?.categoryId;
    _mindMapData = widget.note?.mindMapData;
    _audioUrl = widget.note?.audioUrl;
    _drawingData = widget.note?.drawingData;

    _quillController = _initQuillController(widget.note?.contentJson ?? '');

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingAudio = false);
    });
  }

  quill.QuillController _initQuillController(String rawContent) {
    final trimmed = rawContent.trim();
    if (trimmed.isNotEmpty) {
      if (trimmed.startsWith('[')) {
        try {
          final decoded = jsonDecode(trimmed) as List;
          final doc = quill.Document.fromJson(decoded);
          return quill.QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (_) {}
      }
      final doc = quill.Document()..insert(0, trimmed);
      return quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
    return quill.QuillController.basic();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _titleController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
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
    if (_isSaving) return;
    final title = _titleController.text.trim();
    final plain = _quillController.document.toPlainText().trim();

    if (title.isEmpty &&
        plain.isEmpty &&
        (_mindMapData == null || _mindMapData!.isEmpty) &&
        (_audioUrl == null || _audioUrl!.isEmpty) &&
        (_drawingData == null || _drawingData!.isEmpty)) {
      Navigator.pop(context);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());

    final noteToSave = Note(
      id: widget.note?.id ?? 0,
      userId: widget.note?.userId ?? 0,
      categoryId: _selectedCategoryId,
      title: title.isEmpty ? 'Başlıksız Not' : title,
      contentJson: deltaJson,
      mindMapData: _mindMapData,
      audioUrl: _audioUrl,
      drawingData: _drawingData,
      colorHex: _selectedColorHex,
      isPinned: _isPinned,
      isVault: _isVault,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await context.read<NotesViewModel>().saveNote(noteToSave);
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteNote() async {
    if (widget.note != null && widget.note!.id > 0) {
      await context
          .read<NotesViewModel>()
          .deleteNote(widget.note!.id, fromVault: widget.note!.isVault);
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  // --- Voice Recording & Playback ---
  Future<void> _toggleVoiceRecording() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ses kaydı Android cihazda desteklenir.')),
      );
      return;
    }

    if (_isRecording) {
      _recordTimer?.cancel();
      final recordedPath = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (recordedPath != null && recordedPath.isNotEmpty) {
        String finalUrl = recordedPath;
        if (!mounted) return;
        final uploaded = await context.read<NotesViewModel>().uploadVoiceFile(File(recordedPath));
        if (uploaded != null && uploaded.isNotEmpty) {
          finalUrl = uploaded;
        }
        if (mounted) {
          setState(() => _audioUrl = finalUrl);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesli not kaydedildi!'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ses kaydı için mikrofon izni gereklidir.')),
        );
      }
      return;
    }

    if (await _audioRecorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordSeconds++);
      });
    }
  }

  Future<void> _togglePlayAudio() async {
    if (_audioUrl == null || _audioUrl!.isEmpty) return;

    if (_isPlayingAudio) {
      await _audioPlayer.stop();
      setState(() => _isPlayingAudio = false);
      return;
    }

    try {
      final resolved = ApiService().resolveMediaUrl(_audioUrl!);
      if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
        await _audioPlayer.play(UrlSource(resolved));
      } else {
        await _audioPlayer.play(DeviceFileSource(resolved));
      }
      setState(() => _isPlayingAudio = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ses kaydı oynatılamadı.')),
        );
      }
    }
  }

  // --- Drawing ---
  Future<void> _openDrawing() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => DrawingScreen(initialDrawingJson: _drawingData),
      ),
    );
    if (result != null && mounted) {
      setState(() => _drawingData = result.isEmpty ? null : result);
    }
  }

  void _showCreateLinkedTaskDialog() {
    final ctrl = TextEditingController(text: _titleController.text.trim());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notla İlişkili Görev Oluştur'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Görev Başlığı',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Görev adı boş olamaz.' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.xiaomiOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              await context.read<TasksViewModel>().addTask(
                    ctrl.text.trim(),
                    noteId: widget.note?.id,
                    priority: 'Yüksek',
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Görevler listesine eklendi!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
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
                  final hex =
                      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
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
            tooltip: _isPinned ? 'Sabitlemeyi Kaldır' : 'Sabitle',
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? AppTheme.xiaomiOrange : Colors.grey.shade700,
            ),
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          IconButton(
            tooltip: 'Not Rengi',
            icon: const Icon(Icons.palette_outlined),
            onPressed: _showColorPicker,
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'vault') {
                setState(() => _isVault = !_isVault);
              } else if (val == 'task') {
                _showCreateLinkedTaskDialog();
              } else if (val == 'delete') {
                _deleteNote();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'vault',
                child: Row(
                  children: [
                    Icon(_isVault ? Icons.lock : Icons.lock_open, size: 20, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text(_isVault ? 'Kasadan Çıkar' : 'Gizli Kasaya Ekle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'task',
                child: Row(
                  children: [
                    Icon(Icons.add_task, size: 20, color: AppTheme.xiaomiOrange),
                    SizedBox(width: 8),
                    Text('İlişkili Görev Ekle'),
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
            tooltip: 'Kaydet',
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: AppTheme.xiaomiOrange, strokeWidth: 2),
                  )
                : const Icon(Icons.check, color: AppTheme.xiaomiOrange),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Folder & Metadata bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: widget.categories.any((c) => c.id == _selectedCategoryId)
                          ? _selectedCategoryId
                          : null,
                      hint: const Text('Klasör Seç', style: TextStyle(fontSize: 12)),
                      isDense: true,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Klasörsüz', style: TextStyle(fontSize: 12)),
                        ),
                        ...widget.categories.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.name, style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                  ),
                  const Spacer(),
                  if (_isVault)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 12, color: Colors.deepPurple),
                          SizedBox(width: 4),
                          Text('Gizli Kasa',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Title input with form validation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextFormField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
                decoration: const InputDecoration(
                  hintText: 'Not Başlığı...',
                  hintStyle: TextStyle(color: Colors.black26),
                  border: InputBorder.none,
                ),
                validator: (v) {
                  if (v != null && v.trim().length > 200) {
                    return 'Başlık en fazla 200 karakter olabilir.';
                  }
                  return null;
                },
              ),
            ),

            // Attachments preview strip (Voice Note, Mind Map, Drawing)
            if (_isRecording || _audioUrl != null || _mindMapData != null || _drawingData != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (_isRecording)
                      Chip(
                        backgroundColor: Colors.red.shade50,
                        avatar: const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                        label: Text(
                          'Kaydediliyor... ${_recordSeconds}sn (Durdurmak için dokun)',
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                        onDeleted: _toggleVoiceRecording,
                        deleteIcon: const Icon(Icons.stop_circle, color: Colors.red),
                      ),
                    if (!_isRecording && _audioUrl != null && _audioUrl!.isNotEmpty)
                      InputChip(
                        backgroundColor: Colors.teal.shade50,
                        avatar: Icon(
                          _isPlayingAudio ? Icons.stop : Icons.play_arrow,
                          color: Colors.teal,
                          size: 18,
                        ),
                        label: Text(
                          _isPlayingAudio ? 'Ses Oynatılıyor...' : 'Sesli Notu Dinle',
                          style: const TextStyle(fontSize: 12, color: Colors.teal),
                        ),
                        onPressed: _togglePlayAudio,
                        onDeleted: () => setState(() => _audioUrl = null),
                      ),
                    if (_drawingData != null && _drawingData!.isNotEmpty)
                      InputChip(
                        backgroundColor: Colors.pink.shade50,
                        avatar: const Icon(Icons.brush, color: Colors.pink, size: 16),
                        label: const Text('Çizim Eklendi',
                            style: TextStyle(fontSize: 12, color: Colors.pink)),
                        onPressed: _openDrawing,
                        onDeleted: () => setState(() => _drawingData = null),
                      ),
                  ],
                ),
              ),

            const Divider(height: 1),

            // Flutter Quill Rich Text Toolbar
            Container(
              color: Colors.white.withValues(alpha: 0.7),
              child: quill.QuillSimpleToolbar(
                controller: _quillController,
                config: const quill.QuillSimpleToolbarConfig(
                  multiRowsDisplay: false,
                  showFontFamily: false,
                  showFontSize: false,
                  showSearchButton: false,
                  showSubscript: false,
                  showSuperscript: false,
                  showInlineCode: false,
                  showCodeBlock: false,
                  showLink: false,
                ),
              ),
            ),

            // Flutter Quill Rich Text Editor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: quill.QuillEditor(
                  controller: _quillController,
                  focusNode: _editorFocusNode,
                  scrollController: _editorScrollController,
                  config: const quill.QuillEditorConfig(
                    placeholder: 'Notunuzu zengin metin araçlarıyla yazın...',
                    expands: true,
                    padding: EdgeInsets.only(bottom: 24),
                  ),
                ),
              ),
            ),

            // Xiaomi Bottom Feature Bar (Voice Note, Drawing, Mind Map)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _toolButton(
                      icon: _isRecording ? Icons.stop_circle : Icons.mic_none,
                      label: _isRecording ? 'Durdur (${_recordSeconds}s)' : 'Sesli Not',
                      color: _isRecording ? Colors.red : Colors.teal,
                      onTap: _toggleVoiceRecording,
                    ),
                    _toolButton(
                      icon: Icons.brush_outlined,
                      label: 'Çizim',
                      color: Colors.pink,
                      onTap: _openDrawing,
                    ),
                    _toolButton(
                      icon: Icons.task_alt,
                      label: 'Göreve Dönüştür',
                      color: AppTheme.xiaomiOrange,
                      onTap: _showCreateLinkedTaskDialog,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
