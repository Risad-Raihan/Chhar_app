import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/discount.dart';
import '../utils/app_colors.dart';

class DiscountCard extends StatelessWidget {
  final Discount discount;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final bool showAnimation;

  const DiscountCard({
    Key? key,
    required this.discount,
    required this.onTap,
    this.onFavorite,
    this.showAnimation = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isExpired = discount.isExpired;
    final daysRemaining = discount.daysRemaining();
    final cardWidget = _buildCardContent(context, isExpired, daysRemaining);
    
    // Apply animations conditionally
    return showAnimation 
        ? cardWidget
            .animate()
            .fadeIn(duration: 400.ms, curve: Curves.easeOutQuad)
            .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad)
            .scaleXY(begin: 0.95, end: 1.0, duration: 400.ms) 
        : cardWidget;
  }

  Widget _buildCardContent(BuildContext context, bool isExpired, int daysRemaining) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isExpired 
                  ? Colors.black.withOpacity(0.05)
                  : AppColors.primaryColor.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Discount header with percentage
              _buildDiscountHeader(context),
              
              // Discount content
              _buildDiscountContent(context, isExpired),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountHeader(BuildContext context) {
    // Choose vibrant colors from the new bold palette
    final headerColor = discount.isExpired 
        ? Colors.grey 
        : _getDiscountCategoryColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            headerColor,
            headerColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${discount.discountPercentage.toInt()}% OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
                if (discount.discountPercentage >= 50)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
          // Days left indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                discount.isExpired
                    ? 'Expired'
                    : '${calculateDaysLeft(discount.expiryDate)} days left',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: discount.isExpired ? Colors.red[300] : Colors.green[300],
                    ),
              ),
              // Formatted expiry date with max width constraint
              Container(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  _getFormattedDateRange(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeWidget(bool isExpired, int daysRemaining) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.timer_off : Icons.timer,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isExpired
                ? 'Expired'
                : '$daysRemaining ${daysRemaining == 1 ? 'day' : 'days'} left',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountContent(BuildContext context, bool isExpired) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store logo if available
              if (discount.storeLogoUrl != null && discount.storeLogoUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: discount.storeLogoUrl!,
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceColor,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceColor,
                      child: const Icon(Icons.store, color: AppColors.textSecondaryColor),
                    ),
                  ),
                ),
              
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: discount.storeLogoUrl != null && discount.storeLogoUrl!.isNotEmpty ? 12 : 0,
                    right: 8, // Add some space for the favorite button
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discount.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isExpired ? Colors.grey : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Store: ${discount.store}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              
              _buildFavoriteButton(isExpired),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Description with proper constraints
          Text(
            discount.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isExpired ? Colors.grey : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 12),
          
          // Discount code and expiry date
          _buildCodeAndExpiry(context, isExpired),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(bool isExpired) {
    return IconButton(
      icon: Icon(
        discount.isFavorite ? Icons.favorite : Icons.favorite_border,
        color: discount.isFavorite ? AppColors.primaryColor : AppColors.textSecondaryColor,
        size: 24,
      ),
      onPressed: onFavorite,
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
    ).animate(target: discount.isFavorite ? 1 : 0)
      .scaleXY(begin: 1.0, end: 1.3, duration: 150.ms)
      .then(duration: 150.ms)
      .scaleXY(begin: 1.3, end: 1.0);
  }

  Widget _buildCodeAndExpiry(BuildContext context, bool isExpired) {
    final days = discount.daysRemaining();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isExpired 
                    ? Colors.grey.shade600 
                    : _getDiscountCategoryColor().withOpacity(0.3)
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    discount.code ?? 'No Code',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isExpired ? Colors.grey : Colors.white,
                      letterSpacing: 1,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.copy,
                  size: 16,
                  color: isExpired 
                      ? Colors.grey 
                      : _getDiscountCategoryColor(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Expires:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                DateFormat('MMM dd').format(discount.expiryDate),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isExpired 
                      ? AppColors.errorColor 
                      : days < 3 
                          ? AppColors.warningColor 
                          : AppColors.textSecondaryColor,
                  fontWeight: isExpired || days < 3 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to get a color based on discount category
  Color _getDiscountCategoryColor() {
    final category = discount.category.toLowerCase();
    
    if (category.contains('food') || category.contains('restaurant')) {
      return AppColors.accentOrange;
    } else if (category.contains('tech') || category.contains('electronic')) {
      return AppColors.accentTeal;
    } else if (category.contains('fashion') || category.contains('cloth')) {
      return AppColors.accentPink;
    } else if (category.contains('travel') || category.contains('hotel')) {
      return AppColors.accentCyan;
    } else if (category.contains('book') || category.contains('education')) {
      return AppColors.accentMagenta;
    } else {
      return AppColors.accentLime;
    }
  }

  // Helper method to calculate days left
  int calculateDaysLeft(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);
    return difference.inDays;
  }

  // Helper method to format expiry date with error handling
  String _getFormattedDateRange() {
    try {
      return 'Expires: ${DateFormat.yMMMd().format(discount.expiryDate)}';
    } catch (e) {
      return 'Invalid date';
    }
  }
} 