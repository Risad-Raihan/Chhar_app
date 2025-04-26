import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/store.dart';
import '../models/discount.dart';
import '../services/contentful_service.dart';
import '../utils/app_colors.dart';
import 'discount_detail_screen.dart';

class StoreDetailScreen extends StatefulWidget {
  final Store store;

  const StoreDetailScreen({Key? key, required this.store}) : super(key: key);

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  final ContentfulService _contentfulService = ContentfulService();
  List<Discount> _discounts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStoreDiscounts();
  }

  Future<void> _fetchStoreDiscounts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final discounts = await _contentfulService.getDiscounts(storeId: widget.store.id);
      setState(() {
        _discounts = discounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load discounts: $e';
        _isLoading = false;
      });
      print('Error fetching store discounts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.store.name),
      ),
      body: Column(
        children: [
          // Store Header
          _buildStoreHeader(),
          
          // Discounts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _discounts.isEmpty
                        ? const Center(child: Text('No discounts available for this store'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _discounts.length,
                            itemBuilder: (context, index) {
                              return _buildDiscountCard(_discounts[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Store Logo
          if (widget.store.logoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: widget.store.logoUrl!,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 100,
                  width: 100,
                  color: AppColors.surfaceColor,
                  child: const Icon(Icons.store, size: 50),
                ),
              ),
            )
          else
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.store, size: 50),
            ),
          
          const SizedBox(height: 16),
          
          // Store Name
          Text(
            widget.store.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Store Description
          if (widget.store.description.isNotEmpty)
            Text(
              widget.store.description,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          
          const SizedBox(height: 16),
          
          // Store Website
          if (widget.store.website != null && widget.store.website!.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                // Open website
              },
              icon: const Icon(Icons.public),
              label: const Text('Visit Website'),
            ),
        ],
      ),
    );
  }

  Widget _buildDiscountCard(Discount discount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiscountDetailScreen(discount: discount),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Discount Image
            if (discount.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: discount.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 150,
                    color: AppColors.surfaceColor,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 150,
                    color: AppColors.surfaceColor,
                    child: const Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Discount Title
                  Text(
                    discount.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Discount Percentage
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${discount.discountPercentage.toInt()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Expiry Date
                      Text(
                        'Expires: ${discount.formattedExpiryDate}',
                        style: TextStyle(
                          color: discount.isExpired
                              ? Colors.red
                              : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Discount Description (truncated)
                  Text(
                    discount.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
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