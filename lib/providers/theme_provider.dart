import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider extends ChangeNotifier {
  static const String THEME_KEY = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isThemeChanging = false;
  
  ThemeProvider() {
    _loadThemeFromPrefs();
  }
  
  ThemeMode get themeMode => _themeMode;
  bool get isThemeChanging => _isThemeChanging;
  
  // Load theme preference from shared preferences
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeValue = prefs.getString(THEME_KEY);
    
    if (themeValue != null) {
      _themeMode = themeValue == 'light' ? ThemeMode.light : ThemeMode.dark;
      notifyListeners();
    }
  }
  
  // Save theme preference to shared preferences
  Future<void> _saveThemeToPrefs(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(THEME_KEY, mode == ThemeMode.light ? 'light' : 'dark');
  }
  
  // Toggle between light and dark themes with animation state
  Future<void> toggleTheme() async {
    _isThemeChanging = true;
    notifyListeners();
    
    // Delay to allow animation to start
    await Future.delayed(const Duration(milliseconds: 50));
    
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _saveThemeToPrefs(_themeMode);
    notifyListeners();
    
    // Delay to allow animation to complete
    await Future.delayed(const Duration(milliseconds: 300));
    _isThemeChanging = false;
    notifyListeners();
  }
  
  // Get current theme based on mode
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  // Generate light theme based on dark theme but with light colors
  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.white,
      cardColor: const Color(0xFFF5F5F5),
      primaryColor: AppColors.primaryColor,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        surface: Color(0xFFEEEEEE),
        error: AppColors.errorColor,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).apply(
        fontFamily: 'Outfit',
        fontFamilyFallback: ['NotoSansBengali'],
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          textStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
      dividerColor: Colors.grey[300],
      buttonTheme: const ButtonThemeData(
        buttonColor: AppColors.primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }
  
  // Dark theme (using the existing AppTheme.darkTheme logic)
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.backgroundColor,
      cardColor: AppColors.cardColor,
      primaryColor: AppColors.primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        surface: AppColors.surfaceColor,
        error: AppColors.errorColor,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        fontFamily: 'Outfit',
        fontFamilyFallback: ['NotoSansBengali'],
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardColor,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          textStyle: const TextStyle(
            color: AppColors.textPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryColor),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimaryColor),
      dividerColor: AppColors.dividerColor,
      buttonTheme: const ButtonThemeData(
        buttonColor: AppColors.primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }
} 