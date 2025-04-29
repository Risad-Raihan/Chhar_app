import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/discount.dart';
import '../utils/app_colors.dart';

class DiscountDetailScreen extends StatefulWidget {
  final Discount discount;

  const DiscountDetailScreen({Key? key, required this.discount}) : super(key: key);

  @override
  State<DiscountDetailScreen> createState() => _DiscountDetailScreenState();
}

class _DiscountDetailScreenState extends State<DiscountDetailScreen> {
  bool _isFavorite = false;
  bool _codeCopied = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.discount.isFavorite;
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    // TODO: Implement favorite toggle in shared preferences or backend
  }

  void _copyCode() {
    if (widget.discount.code != null && widget.discount.code!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: widget.discount.code!));
      setState(() {
        _codeCopied = true;
      });
      
      // Reset the copied state after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _codeCopied = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final expired = widget.discount.isExpired;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discount Details'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Discount Image
            if (widget.discount.imageUrl != null)
              Image.network(
                widget.discount.imageUrl!.startsWith('http')
                    ? widget.discount.imageUrl!
                    : 'https:${widget.discount.imageUrl!}',
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading discount image in detail: $error for URL: ${widget.discount.imageUrl}');
                  return Container(
                    height: 250,
                    color: AppColors.surfaceColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_not_supported, size: 80),
                        const SizedBox(height: 8),
                        Text('Failed to load image: ${widget.discount.imageUrl}'),
                        Text('Error: $error', style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  );
                },
              )
            else
              Container(
                height: 250,
                width: double.infinity,
                color: AppColors.surfaceColor,
                child: const Icon(Icons.image_not_supported, size: 80),
              ),
              
            // Discount Info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.discount.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Discount Badge & Expiry
                  Row(
                    children: [
                      // Discount Percentage Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.discount.discountPercentage.toInt()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Expiry Date with Icon
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 20,
                            color: expired ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Expires: ${widget.discount.formattedExpiryDate}',
                            style: TextStyle(
                              color: expired ? Colors.red : Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Expiry Warning
                  if (widget.discount.daysLeft <= 7 && !expired)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.discount.daysLeft <= 0
                            ? 'Expires today!'
                            : 'Expires in ${widget.discount.daysLeft} days!',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                  // Expired Warning
                  if (expired)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'This discount has expired',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                  const SizedBox(height: 24),
                  
                  // Promo Code (if available)
                  if (widget.discount.code != null && widget.discount.code!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Promo Code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.discount.code!,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: expired ? null : _copyCode,
                                icon: Icon(_codeCopied ? Icons.check : Icons.copy),
                                label: Text(_codeCopied ? 'Copied' : 'Copy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _codeCopied
                                      ? Colors.green
                                      : AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Copy this code and use it at checkout',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Display full description if available, otherwise use the short description
                  Text(
                    widget.discount.displayDescription,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // CTA Button
                  if (!expired)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement redeem action
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Redeem functionality will be implemented soon'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Redeem This Offer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 