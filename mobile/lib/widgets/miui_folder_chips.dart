import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

class MiuiFolderChips extends StatelessWidget {
  final List<CategoryItem> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;

  const MiuiFolderChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
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
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
