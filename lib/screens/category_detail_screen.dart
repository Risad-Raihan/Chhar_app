import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/category.dart';
import '../models/discount.dart';
import '../models/store.dart';
import '../services/contentful_service.dart';
import '../utils/app_colors.dart';
import 'discount_detail_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final Category category;

  const CategoryDetailScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final ContentfulService _contentfulService = ContentfulService();
  List<Discount> _discounts = [];
  List<Store> _stores = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCategoryData();
  }

  Future<void> _fetchCategoryData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch discounts and stores for this category
      final discounts = await _contentfulService.getDiscounts(categoryId: widget.category.id);
      final stores = await _contentfulService.getStores(categoryId: widget.category.id);
      
      setState(() {
        _discounts = discounts;
        _stores = stores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
      print('Error fetching category data: $e');
    }
  }

  IconData _getCategoryIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.category;
    }
    
    switch (iconName.toLowerCase()) {
      case 'food':
      case 'restaurant':
      case 'food_dining':
        return Icons.restaurant;
      case 'shopping':
      case 'fashion':
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'electronics':
      case 'devices':
        return Icons.devices;
      case 'travel':
      case 'flight':
        return Icons.flight;
      case 'beauty':
      case 'spa':
        return Icons.spa;
      case 'health':
      case 'medical_services':
        return Icons.medical_services;
      case 'entertainment':
      case 'movie':
        return Icons.movie;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _fetchCategoryData,
                  child: CustomScrollView(
                    slivers: [
                      // Header with category info
                      SliverToBoxAdapter(
                        child: _buildCategoryHeader(),
                      ),
                      
                      // Section title for discounts
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                          child: Text(
                            'Discounts (${_discounts.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      // Discounts grid or empty state
                      _discounts.isEmpty
                          ? SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_offer_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No discounts available for this category',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildDiscountCard(_discounts[index]),
                                  childCount: _discounts.length,
                                ),
                              ),
                            ),
                      
                      // Add some padding at the bottom
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCategoryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLightColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              _getCategoryIcon(widget.category.icon),
              size: 40,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Category Name
          Text(
            widget.category.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Category Description
          if (widget.category.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.category.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          // Stats
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem(
                Icons.local_offer,
                'Discounts',
                _discounts.length.toString(),
              ),
              const SizedBox(width: 32),
              _buildStatItem(
                Icons.store,
                'Stores',
                _stores.length.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primaryColor,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountCard(Discount discount) {
    // Find the store for this discount
    final store = _stores.firstWhere(
      (s) => s.id == discount.storeId,
      orElse: () => Store(
        id: '',
        name: 'Unknown Store',
        description: '',
        categoryIds: [],
        featured: false,
      ),
    );

    return Card(
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: discount.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: discount.imageUrl!.startsWith('http') 
                              ? discount.imageUrl! 
                              : 'https:${discount.imageUrl!}',
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 100,
                            color: AppColors.surfaceColor,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 100,
                            color: AppColors.surfaceColor,
                            child: const Icon(Icons.image_not_supported, size: 40),
                          ),
                        )
                      : Container(
                          height: 100,
                          color: AppColors.surfaceColor,
                          child: const Icon(Icons.image_not_supported, size: 40),
                        ),
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
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${discount.discountPercentage.toInt()}% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    discount.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Store name
                  Text(
                    store.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Days Left
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        discount.daysLeft < 0
                            ? 'Expired'
                            : (discount.daysLeft == 0
                                ? 'Expires today'
                                : 'Ends in ${discount.daysLeft} days'),
                        style: TextStyle(
                          fontSize: 10,
                          color: discount.daysLeft < 0
                              ? Colors.red
                              : (discount.daysLeft < 3
                                  ? Colors.orange
                                  : Colors.grey[600]),
                        ),
                      ),
                    ],
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