import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AnimatedLocationPin extends StatefulWidget {
  final bool isActive;
  final double size;
  
  const AnimatedLocationPin({
    Key? key,
    this.isActive = false,
    this.size = 24,
  }) : super(key: key);

  @override
  State<AnimatedLocationPin> createState() => _AnimatedLocationPinState();
}

class _AnimatedLocationPinState extends State<AnimatedLocationPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(AnimatedLocationPin oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, -_bounceAnimation.value * 4.0),
              child: Transform.scale(
                scale: widget.isActive ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: widget.size,
                  height: widget.size * 1.5,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? AppColors.primaryColor
                        : AppColors.primaryLightColor,
                    borderRadius: BorderRadius.circular(widget.size / 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        blurRadius: widget.isActive ? 8 : 4,
                        spreadRadius: widget.isActive ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.isActive
                                ? AppColors.primaryColor
                                : AppColors.primaryLightColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(widget.size / 2),
                              topRight: Radius.circular(widget.size / 2),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: widget.size * 0.6,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(widget.size / 2),
                            bottomRight: Radius.circular(widget.size / 2),
                          ),
                          child: CustomPaint(
                            painter: TrianglePainter(
                              color: widget.isActive
                                  ? AppColors.primaryColor
                                  : AppColors.primaryLightColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Shadow/reflection
            if (widget.isActive)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: widget.size * 0.6,
                height: 3,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
          ],
        );
      },
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 