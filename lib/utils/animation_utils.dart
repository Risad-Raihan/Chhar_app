import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Utility class for animations that can be reused across the app
class AnimationUtils {
  /// Creates a press effect animation for any widget
  /// 
  /// [child] is the widget to animate
  /// [onTap] is the function to call when the widget is tapped
  /// [scale] is how much the widget should scale down when pressed (default: 0.95)
  /// [duration] is the duration of the animation (default: 150ms)
  static Widget withPressEffect({
    required Widget child, 
    required VoidCallback onTap,
    double scale = 0.95,
    Duration duration = const Duration(milliseconds: 150),
    Duration? delay,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;
        
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) {
            setState(() => isPressed = false);
            onTap();
          },
          onTapCancel: () => setState(() => isPressed = false),
          child: AnimatedScale(
            scale: isPressed ? scale : 1.0,
            duration: duration,
            curve: Curves.easeInOut,
            child: child,
          ),
        );
      },
    );
  }
  
  /// Creates a hover effect animation for any widget
  ///
  /// [child] is the widget to animate
  /// [scale] is how much the widget should scale up when hovered (default: 1.03)
  /// [elevation] is the additional elevation to add when hovered (default: 2)
  /// [duration] is the duration of the animation (default: 150ms)
  static Widget withHoverEffect({
    required Widget child,
    double scale = 1.03,
    double elevation = 2,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: duration,
            transform: Matrix4.identity()..scale(isHovered ? scale : 1.0),
            decoration: BoxDecoration(
              boxShadow: isHovered ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: child,
          ),
        );
      },
    );
  }
  
  /// Creates a pulse animation for any widget (good for drawing attention)
  ///
  /// [child] is the widget to animate
  /// [pulseBetween] the range to pulse between (default: 0.97 to 1.03)
  /// [duration] is the duration of one full pulse cycle (default: 1.5s)
  static Widget withPulseEffect({
    required Widget child,
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 1500),
    double minScale = 0.97,
    double maxScale = 1.03,
  }) {
    return child.animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).scale(
      begin: const Offset(1.0, 1.0) * minScale,
      end: const Offset(1.0, 1.0) * maxScale,
      duration: duration,
      curve: curve,
    );
  }
  
  /// Adds a highlight effect to any widget when it appears on screen
  /// 
  /// [child] is the widget to animate
  /// [duration] is the duration of the animation (default: 600ms)
  static Widget withEntryHighlight({
    required Widget child,
    Color highlightColor = Colors.white,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return child.animate()
      .fadeIn(duration: const Duration(milliseconds: 300))
      .shimmer(
        color: highlightColor.withOpacity(0.8),
        size: 2,
        duration: duration,
      );
  }
  
  /// Adds a staggered slide-in animation for lists
  ///
  /// [child] is the widget to animate
  /// [index] is the position in the list (used to calculate delay)
  /// [baseDelay] is the delay between each item animation (default: 30ms)
  static Widget withStaggeredSlideIn({
    required Widget child,
    required int index,
    Duration baseDelay = const Duration(milliseconds: 30),
  }) {
    return child.animate()
      .fadeIn(
        duration: const Duration(milliseconds: 400),
        delay: Duration(milliseconds: 50 * index),
      )
      .slideY(
        begin: 0.1,
        end: 0,
        duration: const Duration(milliseconds: 400),
        delay: Duration(milliseconds: 50 * index),
        curve: Curves.easeOutQuad,
      );
  }
} 