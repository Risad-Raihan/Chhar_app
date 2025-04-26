import 'package:flutter/material.dart';
import '../styles/colors.dart';

class FilterChipList extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final bool showExpired;
  final VoidCallback onToggleExpired;

  const FilterChipList({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.showExpired,
    required this.onToggleExpired,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Expired filter chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                'Show Expired',
                style: TextStyle(
                  color: showExpired
                      ? Colors.white
                      : (isDarkMode ? Colors.white : AppColors.textDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: showExpired,
              onSelected: (_) => onToggleExpired(),
              backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.grey.shade100,
              selectedColor: AppColors.accentColor,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          
          // Category filter chips
          ...categories.map((category) {
            final isSelected = category == selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  category,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDarkMode ? Colors.white : AppColors.textDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onCategorySelected(category),
                backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.grey.shade100,
                selectedColor: AppColors.primaryColor,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
} 