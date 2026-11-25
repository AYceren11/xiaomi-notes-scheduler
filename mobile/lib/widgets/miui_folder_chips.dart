import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

class MiuiFolderChips extends StatelessWidget {
  final List<CategoryItem> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;
  final VoidCallback? onAddCategory;
  final ValueChanged<CategoryItem>? onLongPressCategory;

  const MiuiFolderChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    this.onAddCategory,
    this.onLongPressCategory,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _buildChip(
            title: 'Tümü',
            isSelected: selectedCategoryId == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...categories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                title: cat.name,
                isSelected: selectedCategoryId == cat.id,
                onTap: () => onSelected(cat.id),
                onLongPress: onLongPressCategory != null
                    ? () => onLongPressCategory!(cat)
                    : null,
              ),
            );
          }),
          if (onAddCategory != null)
            GestureDetector(
              onTap: onAddCategory,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.xiaomiOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.xiaomiOrange.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: AppTheme.xiaomiOrange),
                    SizedBox(width: 4),
                    Text(
                      'Klasör',
                      style: TextStyle(
                        color: AppTheme.xiaomiOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.xiaomiOrange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.xiaomiOrange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
