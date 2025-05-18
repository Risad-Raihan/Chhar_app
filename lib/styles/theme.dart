import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Dark Theme (primary theme)
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryColor,
    primaryColorLight: AppColors.primaryLightColor,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      surface: AppColors.surfaceColor,
      error: AppColors.errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: AppColors.textPrimaryColor,
      onError: Colors.white,
      tertiary: AppColors.accentPink,
    ),
    scaffoldBackgroundColor: AppColors.backgroundColor,
    cardColor: AppColors.cardColor,
    dividerColor: AppColors.dividerColor,
    
    // Updated Text Theme with improved typography
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.textPrimaryColor,
        fontSize: 30,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.25,
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimaryColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.25,
      ),
      headlineSmall: TextStyle(
        color: AppColors.textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimaryColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        color: AppColors.textPrimaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimaryColor,
        fontSize: 16,
        letterSpacing: 0.5,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondaryColor,
        fontSize: 14,
        letterSpacing: 0.25,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: AppColors.textSecondaryColor,
        fontSize: 12,
        letterSpacing: 0.4,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: AppColors.primaryLightColor,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
    
    // Updated AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cardColor,
      foregroundColor: AppColors.textPrimaryColor,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(
        color: AppColors.primaryColor,
      ),
    ),
    
    // Updated Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: AppColors.primaryColor.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    
    // Updated Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.surfaceColor,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: const TextStyle(color: AppColors.textSecondaryColor),
      prefixIconColor: AppColors.primaryLightColor,
      suffixIconColor: AppColors.primaryLightColor,
    ),
    
    // Updated Card Theme
    cardTheme: CardTheme(
      color: AppColors.cardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      shadowColor: Colors.black.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    ),
    
    // Updated Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      extendedPadding: const EdgeInsets.all(16),
    ),
    
    // Updated Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.primaryLightColor,
      size: 24,
    ),
    
    // Updated Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightSurface,
      disabledColor: AppColors.surfaceColor.withOpacity(0.5),
      selectedColor: AppColors.primaryColor,
      secondarySelectedColor: AppColors.secondaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelStyle: const TextStyle(
        color: AppColors.textPrimaryColor,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      brightness: Brightness.dark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide.none,
      ),
    ),
    
    // Updated ListTile Theme
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      selectedTileColor: AppColors.lightSurface,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
    
    // Updated Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceColor,
      contentTextStyle: const TextStyle(color: AppColors.textPrimaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
    ),
    
    // Updated TabBar Theme
    tabBarTheme: const TabBarTheme(
      labelColor: AppColors.primaryColor,
      unselectedLabelColor: AppColors.textSecondaryColor,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          width: 3,
          color: AppColors.primaryColor,
        ),
      ),
    ),
  );

  // Light Theme (updated with matching style)
  static final ThemeData lightTheme = ThemeData.light().copyWith(
    primaryColor: AppColors.primaryColor,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      surface: Color(0xFFF5F5F5),
      background: Colors.white,
      error: AppColors.errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF333333),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFF333333),
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    scaffoldBackgroundColor: Colors.white,
  );
} 