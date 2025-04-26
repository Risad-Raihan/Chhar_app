import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// This is a widget for the custom marker design
// Note: We need to convert this to BitmapDescriptor for Google Maps
class MapMarkerWidget extends StatelessWidget {
  final String title;
  final String? logoUrl;
  final bool isSelected;
  final Color color;

  const MapMarkerWidget({
    Key? key,
    required this.title,
    this.logoUrl,
    this.isSelected = false,
    this.color = AppColors.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected ? color : color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo or Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: logoUrl != null && logoUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      logoUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.store,
                    color: color,
                    size: 20,
                  ),
          ),
          
          // Title (only shown when selected)
          if (isSelected && title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 80),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
          // Triangle at bottom
          Transform.translate(
            offset: const Offset(0, 4),
            child: Container(
              width: 12,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 