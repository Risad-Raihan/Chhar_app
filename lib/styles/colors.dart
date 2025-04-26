import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primaryColor = Color(0xFF2196F3); // Bright Blue
  static const Color primaryLightColor = Color(0xFF64B5F6);
  static const Color primaryDarkColor = Color(0xFF1976D2);
  
  // Secondary colors
  static const Color accentColor = Color(0xFFFF4081); // Pink
  static const Color accentLightColor = Color(0xFFFF80AB);
  static const Color accentDarkColor = Color(0xFFF50057);
  
  // Text colors
  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF666666);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color textGrey = Color(0xFF757575);
  static const Color textGreyLight = Color(0xFFBDBDBD);
  
  // Background colors
  static const Color background = Color(0xFFFFFFFF); // Pure white
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFEEEEEE);
  
  // Dark theme colors
  static const Color surfaceDark = Color(0xFF303030);
  static const Color backgroundDark = Color(0xFF212121);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF2196F3);
  
  // Social media colors
  static const Color facebook = Color(0xFF3B5998);
  static const Color google = Color(0xFFDB4437);
  
  // Discount colors
  static const Color discountRed = Color(0xFFE53935);
  static const Color discountGreen = Color(0xFF43A047);
  static const Color discountAmber = Color(0xFFFFB300);
  
  // Gradient colors
  static const List<Color> primaryGradient = [
    primaryColor,
    primaryLightColor,
  ];
  
  static const List<Color> accentGradient = [
    accentColor,
    Color(0xFFFF80AB),
  ];
} 