import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedThemeWrapper extends StatelessWidget {
  final Widget child;
  
  const AnimatedThemeWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isChanging = themeProvider.isThemeChanging;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      color: isDark ? Colors.black : Colors.white,
      child: AnimatedOpacity(
        opacity: isChanging ? 0.8 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: child.animate(target: isChanging ? 1.0 : 0.0)
          .saturate(
            begin: 0.8,
            end: 1.0,
            duration: const Duration(milliseconds: 300),
          )
          .blurXY(
            begin: isChanging ? 2.0 : 0.0, 
            end: 0.0,
            duration: const Duration(milliseconds: 300),
          ),
      ),
    );
  }
} 