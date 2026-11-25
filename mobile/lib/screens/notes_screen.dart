import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../widgets/miui_folder_chips.dart';
import '../widgets/miui_search_bar.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';
import 'settings_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEditor([Note? note]) async {
    final vm = context.read<NotesViewModel>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          note: note,
          categories: vm.categories,
        ),
      ),
    );
  }

  void _showCategoryDialog([CategoryItem? existing]) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String selectedColor = existing?.colorCode ?? '#FF6900';
    final colors = ['#FF6900', '#2196F3', '#4CAF50', '#9C27B0', '#E91E63', '#009688'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'Yeni Klasör Oluştur' : 'Klasörü Düzenle'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Klasör Adı',
                    hintText: 'Örn: Üniversite, Projeler...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Klasör adı boş olamaz.';
                    if (v.trim().length > 60) return 'En fazla 60 karakter olabilir.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  children: colors.map((hex) {
                    final color = Color(int.parse('FF${hex.substring(1)}', radix: 16));
                    final isSel = hex == selectedColor;
                    return GestureDetector(
                      onTap: () => setDlgState(() => selectedColor = hex),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: color,
                        child: isSel
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await this.context.read<NotesViewModel>().removeCategory(existing.id);
                },
                child: const Text('Sil', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.xiaomiOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final vm = this.context.read<NotesViewModel>();
                if (existing == null) {
                  await vm.addCategory(nameCtrl.text.trim(), selectedColor, 'folder');
                } else {
                  await vm.editCategory(existing.id, nameCtrl.text.trim(), selectedColor, existing.icon);
                }
              },
              child: Text(existing == null ? 'Oluştur' : 'Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotesViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xiaomi Notlar'),
        actions: [
          IconButton(
            tooltip: vm.isMasonryGrid ? 'Liste Görünümü' : 'Masonry Izgara',
            icon: Icon(vm.isMasonryGrid ? Icons.view_agenda_outlined : Icons.dashboard_outlined),
            onPressed: vm.toggleViewMode,
          ),
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          MiuiSearchBar(
            controller: _searchController,
            onChanged: (q) => vm.search(q),
            onClear: () => vm.search(''),
          ),
          MiuiFolderChips(
            categories: vm.categories,
            selectedCategoryId: vm.selectedCategoryId,
            onSelected: (id) => vm.selectCategory(id),
            onAddCategory: () => _showCategoryDialog(),
            onLongPressCategory: (cat) => _showCategoryDialog(cat),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.xiaomiOrange))
                : vm.notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              vm.error ?? 'Henüz not eklenmemiş',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                              textAlign: TextAlign.center,
                            ),
                            if (vm.error != null) ...[
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: vm.loadAll,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tekrar Dene'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.xiaomiOrange,
                        onRefresh: vm.loadAll,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (!vm.isMasonryGrid) {
                              return ListView.builder(
                                padding: const EdgeInsets.only(bottom: 88),
                                itemCount: vm.notes.length,
                                itemBuilder: (context, index) {
                                  final note = vm.notes[index];
                                  return NoteCard(
                                    note: note,
                                    isGrid: false,
                                    onTap: () => _openEditor(note),
                                    onTogglePin: () => vm.togglePin(note.id),
                                    onToggleVault: () => vm.toggleVault(note.id),
                                    onDelete: () => vm.deleteNote(note.id),
                                  );
                                },
                              );
                            }

                            final crossAxisCount = constraints.maxWidth >= 900
                                ? 4
                                : constraints.maxWidth >= 600
                                    ? 3
                                    : 2;

                            return MasonryGridView.count(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 88),
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              itemCount: vm.notes.length,
                              itemBuilder: (context, index) {
                                final note = vm.notes[index];
                                return NoteCard(
                                  note: note,
                                  isGrid: true,
                                  onTap: () => _openEditor(note),
                                  onTogglePin: () => vm.togglePin(note.id),
                                  onToggleVault: () => vm.toggleVault(note.id),
                                  onDelete: () => vm.deleteNote(note.id),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes_fab',
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
