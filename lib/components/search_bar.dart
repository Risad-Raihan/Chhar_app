import 'package:flutter/material.dart';
import '../styles/colors.dart';

class CustomSearchBar extends StatelessWidget {
  final Function(String) onChanged;
  final TextEditingController? controller;
  final String hintText;

  const CustomSearchBar({
    Key? key,
    required this.onChanged,
    this.controller,
    this.hintText = 'Search for discounts, stores, etc.',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            Icons.search,
            color: isDarkMode ? AppColors.textGreyLight : AppColors.textGrey,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.filter_list,
              color: isDarkMode ? AppColors.textGreyLight : AppColors.textGrey,
            ),
            onPressed: () {
              // Show filter options
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDarkMode 
              ? AppColors.surfaceDark.withAlpha(204)
              : Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        style: TextStyle(
          color: isDarkMode ? Colors.white : AppColors.textDark,
          fontSize: 14,
        ),
      ),
    );
  }
} 