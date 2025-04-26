import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../utils/app_colors.dart';

class AnimatedLoading extends StatelessWidget {
  final String animationType;
  final double size;
  final Color? color;
  final String? message;
  final bool repeat;

  const AnimatedLoading({
    Key? key,
    this.animationType = 'loading',
    this.size = 200,
    this.color,
    this.message,
    this.repeat = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LottieAnimation(
            animationType: animationType,
            size: size,
            color: color,
            repeat: repeat,
          ),
          if (message != null) 
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                message!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color ?? Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class LottieAnimation extends StatelessWidget {
  final String animationType;
  final double size;
  final Color? color;
  final bool repeat;
  final BoxFit fit;

  const LottieAnimation({
    Key? key,
    required this.animationType,
    this.size = 200,
    this.color,
    this.repeat = true,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Builder(
        builder: (context) {
          try {
            return Lottie.asset(
              _getAnimationPath(),
              fit: fit,
              repeat: repeat,
              delegates: color != null ? LottieDelegates(
                values: [
                  ValueDelegate.color(
                    const ['**'],
                    value: color,
                  ),
                ],
              ) : null,
              errorBuilder: (context, error, stackTrace) {
                print('Lottie error: $error');
                // Fallback for animation loading errors
                return _buildFallbackIcon();
              },
            );
          } catch (e) {
            print('Lottie exception: $e');
            // Fallback for any other errors
            return _buildFallbackIcon();
          }
        }
      ),
    );
  }

  Widget _buildFallbackIcon() {
    IconData iconData;
    Color iconColor = color ?? Colors.white;
    
    switch (animationType) {
      case 'discount':
        iconData = Icons.local_offer;
        break;
      case 'search':
        iconData = Icons.search;
        break;
      case 'location':
        iconData = Icons.location_on;
        break;
      case 'fire':
        iconData = Icons.local_fire_department;
        break;
      case 'empty':
        iconData = Icons.inbox;
        break;
      case 'error':
        iconData = Icons.error_outline;
        break;
      case 'success':
        iconData = Icons.check_circle_outline;
        break;
      default:
        iconData = Icons.animation;
    }
    
    return Icon(
      iconData,
      size: size * 0.6,
      color: iconColor,
    );
  }

  String _getAnimationPath() {
    switch (animationType) {
      case 'loading':
        return 'assets/animations/loading.json';
      case 'empty':
        return 'assets/animations/empty_box.json';
      case 'error':
        return 'assets/animations/error.json';
      case 'success':
        return 'assets/animations/success.json';
      case 'discount':
        return 'assets/animations/discount_tag.json';
      case 'discount_deal':
        return 'assets/animations/discount_deal.json';
      case 'confetti':
        return 'assets/animations/confetti.json';
      case 'search':
        return 'assets/animations/search.json';
      case 'location':
        return 'assets/animations/location_pin.json';
      case 'fire':
        return 'assets/animations/fire.json';
      default:
        return 'assets/animations/loading.json';
    }
  }
}

class AnimatedPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color color;

  const AnimatedPlaceholder({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.color = AppColors.surfaceColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
            color.withOpacity(0.6),
            color.withOpacity(0.8),
            color,
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
    );
  }
} 