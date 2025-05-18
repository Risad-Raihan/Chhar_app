import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/discount.dart';
import '../utils/app_colors.dart';

class DiscountCard extends StatefulWidget {
  final Discount discount;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final bool showAnimation;
  final bool isGridView;

  const DiscountCard({
    Key? key,
    required this.discount,
    required this.onTap,
    this.onFavorite,
    this.showAnimation = true,
    this.isGridView = false,
  }) : super(key: key);

  @override
  State<DiscountCard> createState() => _DiscountCardState();
}

class _DiscountCardState extends State<DiscountCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller for subtle pulse effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Only animate hot deals with high discount percentages
    if (widget.discount.discountPercentage < 40) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isGridView) {
      return _buildGridCard(context);
    }
    return _buildListCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.discount.discountPercentage >= 40 ? _pulseAnimation.value : 1.0,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) {
                setState(() => _isPressed = false);
                widget.onTap();
              },
              onTapCancel: () => setState(() => _isPressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()
                  ..translate(0.0, _isPressed ? 2.0 : 0.0)
                  ..scale(_isPressed ? 0.98 : _isHovered ? 1.02 : 1.0),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: _isHovered ? 10 : 4,
                  shadowColor: _isHovered 
                    ? AppColors.primaryColor.withOpacity(0.4)
                    : Colors.black.withOpacity(0.2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Discount Image
                      AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (widget.discount.imageUrl != null)
                              CachedNetworkImage(
                                imageUrl: widget.discount.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[800],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.error),
                                ),
                              )
                            else
                              Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.local_offer, size: 48),
                              ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentTeal.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${widget.discount.discountPercentage}% OFF',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (widget.discount.discountPercentage >= 40)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.local_fire_department,
                                          color: Colors.orange,
                                          size: 16,
                                        ),
                                      ).animate(autoPlay: true).shimmer(
                                        duration: const Duration(milliseconds: 1200),
                                        delay: const Duration(milliseconds: 500),
                                      ),
                                  ],
                                ),
                              ).animate(autoPlay: true)
                                .fadeIn(duration: const Duration(milliseconds: 250))
                                .slideX(begin: 0.2, end: 0, duration: const Duration(milliseconds: 250)),
                            ),
                            // Add a subtle gradient overlay when hovered
                            if (_isHovered)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.center,
                                      colors: [
                                        Colors.black.withOpacity(0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ).animate().fadeIn(duration: const Duration(milliseconds: 200)),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.discount.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (widget.discount.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.discount.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            // Expiry with animated indicator
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: _getRemainingTimeColor(),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Valid until ${DateFormat('MMM dd, yyyy').format(widget.discount.expiryDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getRemainingTimeColor(),
                                      fontWeight: _isUrgent() ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (_isHovered)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryColor.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'View Details',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: const Duration(milliseconds: 200)).slideY(begin: 0.2, end: 0),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListCard(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.discount.discountPercentage >= 40 ? _pulseAnimation.value : 1.0,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) {
                setState(() => _isPressed = false);
                widget.onTap();
              },
              onTapCancel: () => setState(() => _isPressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()
                  ..translate(0.0, _isPressed ? 2.0 : 0.0)
                  ..scale(_isPressed ? 0.98 : _isHovered ? 1.01 : 1.0),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: _isHovered ? 10 : 4,
                  shadowColor: _isHovered 
                    ? AppColors.primaryColor.withOpacity(0.4)
                    : Colors.black.withOpacity(0.2),
                  child: Row(
                    children: [
                      // Discount Image
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (widget.discount.imageUrl != null)
                              CachedNetworkImage(
                                imageUrl: widget.discount.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[800],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.error),
                                ),
                              )
                            else
                              Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.local_offer, size: 48),
                              ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentTeal.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${widget.discount.discountPercentage}% OFF',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (widget.discount.discountPercentage >= 40)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.local_fire_department,
                                          color: Colors.orange,
                                          size: 16,
                                        ),
                                      ).animate(autoPlay: true).shimmer(
                                        duration: const Duration(milliseconds: 1200),
                                        delay: const Duration(milliseconds: 500),
                                      ),
                                  ],
                                ),
                              ).animate(autoPlay: true)
                                .fadeIn(duration: const Duration(milliseconds: 250))
                                .slideX(begin: 0.2, end: 0, duration: const Duration(milliseconds: 250)),
                            ),
                            // Add a subtle gradient overlay when hovered
                            if (_isHovered)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.3),
                                      ],
                                    ),
                                  ),
                                ).animate().fadeIn(duration: const Duration(milliseconds: 200)),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.discount.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (widget.discount.description != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.discount.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  // Expiry with animated indicator
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: _getRemainingTimeColor(),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Valid until ${DateFormat('MMM dd, yyyy').format(widget.discount.expiryDate)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _getRemainingTimeColor(),
                                            fontWeight: _isUrgent() ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Overlay for "View Details" on hover
                            if (_isHovered)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryColor.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'View Details',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(duration: const Duration(milliseconds: 200)).slideX(begin: 0.2, end: 0),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  // Helper method to determine if the discount expiry is urgent
  bool _isUrgent() {
    final daysLeft = widget.discount.daysLeft;
    return daysLeft <= 3 && daysLeft >= 0;
  }

  // Helper method to get appropriate color based on remaining time
  Color _getRemainingTimeColor() {
    if (widget.discount.isExpired) {
      return Colors.red;
    } else if (widget.discount.daysLeft <= 3) {
      return Colors.orange;
    } else if (widget.discount.daysLeft <= 7) {
      return Colors.yellow;
    } else {
      return Colors.grey[400]!;
    }
  }

  // ... existing code for other helper methods ...
} 