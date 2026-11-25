import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final bool isGrid;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback? onToggleVault;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.note,
    this.isGrid = true,
    required this.onTap,
    required this.onTogglePin,
    this.onToggleVault,
    this.onDelete,
  });

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            ListTile(
              leading: Icon(
                note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: AppTheme.xiaomiOrange,
              ),
              title: Text(note.isPinned ? 'Sabitlemeyi Kaldır' : 'Notu Sabitle'),
              onTap: () {
                Navigator.pop(ctx);
                onTogglePin();
              },
            ),
            if (onToggleVault != null)
              ListTile(
                leading: Icon(
                  note.isVault ? Icons.lock_open : Icons.lock_outline,
                  color: Colors.deepPurple,
                ),
                title: Text(note.isVault ? 'Gizli Kasadan Çıkar' : 'Gizli Kasaya Taşı'),
                onTap: () {
                  Navigator.pop(ctx);
                  onToggleVault!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Notu Sil', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete!();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(note.colorHex);
    final dateFormat = DateFormat('dd MMM, HH:mm', 'tr_TR');
    final preview = note.plainTextPreview;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: Container(
        margin: isGrid
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.title.isEmpty ? 'Başlıksız Not' : note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                      height: 1.25,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onTogglePin,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 18,
                      color: note.isPinned ? AppTheme.xiaomiOrange : Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                preview,
                maxLines: isGrid ? 5 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
            ],
            if (note.hasAudio || note.hasMindMap || note.hasDrawing || note.categoryName != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (note.categoryName != null)
                    _badge(Icons.folder_outlined, note.categoryName!, AppTheme.xiaomiOrange),
                  if (note.hasAudio)
                    _badge(Icons.mic, 'Sesli Not', Colors.teal),
                  if (note.hasMindMap)
                    _badge(Icons.account_tree_outlined, 'Zihin Haritası', Colors.indigo),
                  if (note.hasDrawing)
                    _badge(Icons.brush_outlined, 'Çizim', Colors.pink),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (note.isVault) ...[
                  const Icon(Icons.lock, size: 13, color: Colors.deepPurple),
                  const SizedBox(width: 4),
                  const Text(
                    'Kasa',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    dateFormat.format(note.updatedAt.toLocal()),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
