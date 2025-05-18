import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedThemeToggle extends StatelessWidget {
  const AnimatedThemeToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return GestureDetector(
      onTap: () {
        themeProvider.toggleTheme();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: isDark 
              ? AppColors.cardColor
              : const Color(0xFFE0E0E0),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background icons
            Positioned(
              left: 8,
              top: 6,
              child: Icon(
                Icons.wb_sunny_outlined,
                size: 18,
                color: isDark 
                    ? Colors.grey.withOpacity(0.5)
                    : AppColors.accentYellow,
              ).animate(target: isDark ? 0.0 : 1.0)
                .fadeIn(duration: const Duration(milliseconds: 200)),
            ),
            Positioned(
              right: 8,
              top: 6,
              child: Icon(
                Icons.nightlight_round,
                size: 18,
                color: isDark 
                    ? AppColors.accentCyan
                    : Colors.grey.withOpacity(0.5),
              ).animate(target: isDark ? 1.0 : 0.0)
                .fadeIn(duration: const Duration(milliseconds: 200)),
            ),
            
            // Animated toggle
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: isDark ? 32 : 2,
              top: 2,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark 
                      ? AppColors.accentTeal
                      : AppColors.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isDark
                        ? const Icon(
                            Icons.nightlight_round,
                            size: 16,
                            color: Colors.white,
                            key: ValueKey('moon'),
                          )
                        : const Icon(
                            Icons.wb_sunny_outlined,
                            size: 16,
                            color: Colors.white,
                            key: ValueKey('sun'),
                          ),
                  ),
                ),
              ).animate()
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                ),
            ),
          ],
        ),
      ),
    );
  }
} 