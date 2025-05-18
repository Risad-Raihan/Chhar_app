import 'package:flutter/material.dart';

class AppColors {
  // Green-based dark theme palette - updated with more vibrant and cohesive colors
  static const Color primaryColor = Color(0xFF4CAF50);        // Vibrant green
  static const Color primaryLightColor = Color(0xFF81C784);   // Light green
  static const Color secondaryColor = Color(0xFF009688);      // Teal base
  
  static const Color backgroundColor = Color(0xFF121212);     // Dark background
  static const Color cardColor = Color(0xFF1E1E1E);          // Card background
  static const Color surfaceColor = Color(0xFF242424);        // Surface color for cards, etc.
  
  static const Color textPrimaryColor = Colors.white;         // White text
  static const Color textSecondaryColor = Color(0xFFB0B0B0);  // Light grey text
  
  static const Color errorColor = Color(0xFFF44336);          // Error red
  static const Color dividerColor = Color(0xFF323232);        // Divider grey
  
  // Additional colors for playful UI
  static const Color successColor = Color(0xFF4CAF50);        // Success green
  static const Color warningColor = Color(0xFFFFB74D);        // Warning amber
  
  // Accent colors for UI interest - updated for better harmony
  static const Color accentPurple = Color(0xFF7E57C2);        // Accent purple
  static const Color accentPink = Color(0xFFEC407A);          // Accent pink
  static const Color accentYellow = Color(0xFFFFD54F);        // Accent yellow
  
  // Vibrant accent colors
  static const Color accentTeal = Color(0xFF26A69A);          // Vibrant teal
  static const Color accentOrange = Color(0xFFFF7043);        // Vibrant orange
  static const Color accentMagenta = Color(0xFFAB47BC);       // Vibrant magenta
  static const Color accentLime = Color(0xFFD4E157);          // Lime green for contrast
  static const Color accentCyan = Color(0xFF26C6DA);          // Bright cyan
  
  // Light surface color
  static const Color lightSurface = Color(0xFF2C2C2C);        // Lighter surface for contrast
  
  // Gradient primary colors
  static const List<Color> primaryGradient = [
    primaryColor,
    Color(0xFF388E3C),  // Slightly darker primary for gradient
  ];
  
  // Gradient secondary colors
  static const List<Color> secondaryGradient = [
    secondaryColor,
    Color(0xFF00796B),  // Slightly darker secondary for gradient
  ];
} 