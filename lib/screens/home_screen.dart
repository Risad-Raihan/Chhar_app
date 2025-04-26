import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../models/category.dart';
import '../models/store.dart';
import '../models/discount.dart';
import '../services/contentful_service.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';
import '../components/discount_card.dart';
import '../components/animated_loading.dart';
import 'location_search_screen.dart';
import 'category_search_screen.dart';
import 'discount_detail_screen.dart';
import 'store_detail_screen.dart';
import 'category_detail_screen.dart';
import 'package:flutter/foundation.dart' hide Category;

// Data result class for isolate computation
class DataResult {
  final List<Category> categories;
  final List<Store> featuredStores;
  final List<Discount> featuredDiscounts;
  final String? error;

  DataResult({
    this.categories = const [],
    this.featuredStores = const [],
    this.featuredDiscounts = const [],
    this.error,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ContentfulService _contentfulService = ContentfulService();
  
  List<Category> _categories = [];
  List<Store> _featuredStores = [];
  List<Discount> _featuredDiscounts = [];
  
  bool _isLoading = true;
  bool _isCategoriesLoading = true;
  bool _isStoresLoading = true;
  bool _isDiscountsLoading = true;
  String? _error;
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    // Force fetch data from Contentful every time the app starts
    _fetchData();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _isCategoriesLoading = true;
      _isStoresLoading = true;
      _isDiscountsLoading = true;
      _error = null;
    });

    try {
      // Use try/catch here for better error handling on the main thread
      final result = await compute(_fetchDataInBackground, <String, dynamic>{})
          .catchError((e) {
        throw Exception('Failed to process data: $e');
      });
      
      if (result.error != null) {
        setState(() {
          _error = result.error;
          _isLoading = false;
        });
        return;
      }
      
      // Use empty lists as fallbacks
      final categories = result.categories.isNotEmpty ? result.categories : <Category>[];
      final featuredStores = result.featuredStores.isNotEmpty ? result.featuredStores : <Store>[];
      final featuredDiscounts = result.featuredDiscounts.isNotEmpty ? result.featuredDiscounts : <Discount>[];
      
      // Simulate staggered loading for a better UX
      if (mounted) {
        setState(() {
          _categories = categories;
          _isCategoriesLoading = false;
        });
      }
      
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _featuredStores = featuredStores;
          _isStoresLoading = false;
        });
      }
      
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _featuredDiscounts = featuredDiscounts;
          _isDiscountsLoading = false;
          _isLoading = false;
        });
        _controller.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
          _isLoading = false;
          _isCategoriesLoading = false;
          _isStoresLoading = false;
          _isDiscountsLoading = false;
        });
      }
      print('Error fetching data: $e');
    }
  }

  // Function to run in isolate
  static Future<DataResult> _fetchDataInBackground(Map<String, dynamic> _) async {
    try {
      final contentfulService = ContentfulService();
      
      List<Category> categories = [];
      List<Store> stores = [];
      List<Discount> featuredDiscounts = [];
      
      try {
        categories = await contentfulService.getCategories();
        print('Found ${categories.length} categories from Contentful');
      } catch (e) {
        print('Error fetching categories: $e');
        // Continue execution even if categories fail
        categories = [];
      }
      
      try {
        // Get stores, specifically requesting featured ones
        final allStores = await contentfulService.getStores();
        // Filter to get only featured stores
        stores = allStores.where((store) => store.featured).toList();
        print('Found ${stores.length} featured stores from ${allStores.length} total stores');
      } catch (e) {
        print('Error fetching stores: $e');
        // Continue execution even if stores fail
        stores = [];
      }
      
      try {
        // Try to get featured discounts directly
        print('Attempting to fetch featured discounts from Contentful');
        featuredDiscounts = await contentfulService.getFeaturedDiscounts();
        print('Fetched ${featuredDiscounts.length} featured discounts directly');
        
        // Filter out any discounts that match mock data patterns
        final originalCount = featuredDiscounts.length;
        featuredDiscounts = featuredDiscounts.where((d) => 
          !['Flash Sale', 'New User Special', 'Limited Time Offer'].contains(d.title)
        ).toList();
        
        if (originalCount != featuredDiscounts.length) {
          print('Filtered out ${originalCount - featuredDiscounts.length} suspected mock discounts');
        }
        
        // Sort by expiry date
        if (featuredDiscounts.isNotEmpty) {
          featuredDiscounts.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        }
        
        print('Final featured discounts: ${featuredDiscounts.length}');
        if (featuredDiscounts.isNotEmpty) {
          print('Featured discount titles: ${featuredDiscounts.map((d) => d.title).join(', ')}');
        }
      } catch (e) {
        print('Error processing discounts: $e');
        // Continue execution even if discounts fail
        featuredDiscounts = [];
      }
      
      return DataResult(
        categories: categories,
        featuredStores: stores,
        featuredDiscounts: featuredDiscounts,
      );
    } catch (e) {
      print('Critical error in background fetch: $e');
      return DataResult(error: 'Error fetching data: $e');
    }
  }

  void _navigateToLocationSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationSearchScreen()),
    );
  }

  void _navigateToCategorySearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategorySearchScreen()),
    );
  }
  
  void _navigateToDiscountDetail(Discount discount) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscountDetailScreen(
          discount: discount,
        ),
      ),
    );
  }
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildAnimatedAppBar(innerBoxIsScrolled),
            ];
          },
          body: _error != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: AppColors.accentTeal,
                  backgroundColor: AppColors.cardColor,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Header with animation
                        _buildWelcomeHeader(),
                        
                        // Search Cards - Two big tiles for location and category search
                        _buildSearchCardsSection(),
                        
                        const SizedBox(height: 20),
                        
                        // Featured Stores Section
                        _buildFeaturedStoresSection(),
                        
                        // Featured Discounts Section (only shows data from Contentful)
                        _buildFeaturedDiscountsSection(),
                        
                        // Categories Section
                        _buildCategoriesSection(),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add discount functionality
        },
        backgroundColor: AppColors.accentMagenta,
        tooltip: 'Add Discount',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAnimatedAppBar(bool innerBoxIsScrolled) {
    final appBar = SliverAppBar(
      expandedHeight: 70.0,
      floating: true,
      pinned: true,
      snap: true,
      title: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accentTeal.withOpacity(0.9),
              AppColors.accentMagenta.withOpacity(0.9),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Row(
          children: [
            Icon(
              Icons.local_offer,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'Discount Hub',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      elevation: 0,
      backgroundColor: innerBoxIsScrolled ? AppColors.backgroundColor : Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.accentTeal,
          onPressed: () {
            // Navigate to notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          color: AppColors.accentMagenta,
          onPressed: () async {
            // Sign out using the context provider
            final authService = Provider.of<AuthService>(context, listen: false);
            await authService.signOut();
          },
        ),
      ],
    );
    
    // Return the SliverAppBar directly instead of trying to animate it
    return appBar;
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie animation for error
          const AnimatedLoading(
            animationType: 'error',
            size: 180,
            color: AppColors.errorColor,
            repeat: true,
            message: 'Something went wrong',
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'Could not load content',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentTeal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
  
  Widget _buildWelcomeHeader() {
    final user = Provider.of<AuthService>(context).currentUser;
    final greeting = _getGreeting();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, ${user?.displayName?.split(' ').first ?? 'User'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover the best deals from your favorite stores',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryColor,
            ),
          ),
        ],
      ),
    ).animate(controller: _controller)
      .fadeIn(duration: 300.ms);
  }
  
  Widget _buildSearchCardsSection() {
    return Column(
      children: [
        // Search by Location Card - Full width 
        _buildSearchCard(
          animationType: 'location',
          title: 'Search by Location',
          subtitle: 'Find deals near you',
          onTap: _navigateToLocationSearch,
          color: AppColors.accentTeal,
          delay: 100,
          isLarge: true,
        ),
        
        const SizedBox(height: 12),
        
        // Search by Category Card - Full width
        _buildSearchCard(
          animationType: 'search',
          title: 'Search by Category',
          subtitle: 'Browse deals by type',
          onTap: _navigateToCategorySearch,
          color: AppColors.accentOrange,
          delay: 200,
          isLarge: true,
        ),
      ],
    );
  }
  
  Widget _buildSearchCard({
    required String animationType,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    required int delay,
    required bool isLarge,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          height: isLarge ? 130 : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppColors.cardColor,
                AppColors.cardColor,
                color.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: EdgeInsets.all(isLarge ? 16 : 12),
          child: isLarge
              ? Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              animationType == 'location' ? 'Find Nearby Stores' : 'Browse Categories',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Simple icon instead of animation
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForType(animationType),
                        size: 30,
                        color: color,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Static icon instead of animation
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForType(animationType),
                        size: 20,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Text content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    ).animate(controller: _controller)
      .fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms);
  }
  
  IconData _getIconForType(String type) {
    switch (type) {
      case 'location':
        return Icons.location_on;
      case 'search':
        return Icons.search;
      case 'discount':
        return Icons.local_offer;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.info;
    }
  }
  
  Widget _buildFeaturedStoresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Featured Stores',
          icon: Icons.store,
          color: AppColors.accentMagenta,
          delay: 300,
        ),
        const SizedBox(height: 12),
        _isStoresLoading
            ? _buildStoreLoadingShimmer()
            : _featuredStores.isEmpty
                ? _buildEmptyStateMessage('No featured stores available')
                : SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _featuredStores.length,
                      itemBuilder: (context, index) {
                        final store = _featuredStores[index];
                        return _buildStoreCard(store, index);
                      },
                    ),
                  ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildStoreLoadingShimmer() {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: AppColors.surfaceColor,
            highlightColor: AppColors.cardColor,
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoreCard(Store store, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreDetailScreen(store: store),
          ),
        );
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Store logo
            Container(
              height: 70,
              width: 70,
              decoration: const BoxDecoration(
                color: AppColors.surfaceColor,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: store.logo != null && store.logo!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: store.logo!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentMagenta),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.store,
                        color: AppColors.accentMagenta,
                      ),
                    )
                  : const Icon(
                      Icons.store,
                      color: AppColors.accentMagenta,
                      size: 30,
                    ),
            ),
            const SizedBox(height: 8),
            // Store name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                store.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ).animate(controller: _controller)
      .fadeIn(
        delay: Duration(milliseconds: 400 + (index * 50)), 
        duration: const Duration(milliseconds: 300),
      );
  }

  Widget _buildFeaturedDiscountsSection() {
    // Don't show the section at all if there are no real discounts
    if (_featuredDiscounts.isEmpty) {
      return Container(); // Return empty container to hide the section
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              title: 'Featured Discounts',
              icon: Icons.local_offer,
              color: AppColors.accentMagenta,
              delay: 300,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchData,
              tooltip: 'Refresh discounts',
              iconSize: 20,
              color: AppColors.accentTeal,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _isDiscountsLoading
            ? _buildDiscountLoadingShimmer()
            : Column(
                children: List.generate(_featuredDiscounts.length, (index) {
                  final discount = _featuredDiscounts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DiscountCard(
                      key: ValueKey('discount_${discount.id}'),
                      discount: discount,
                      onTap: () => _navigateToDiscountDetail(discount),
                      showAnimation: false,
                    ),
                  );
                }),
              ),
      ],
    );
  }

  Widget _buildDiscountLoadingShimmer() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surfaceColor,
          highlightColor: AppColors.cardColor,
          child: Container(
            height: 160,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Categories',
          icon: Icons.category,
          color: AppColors.accentTeal,
          delay: 900,
        ),
        const SizedBox(height: 12),
        _isCategoriesLoading
            ? _buildCategoryLoadingShimmer()
            : _categories.isEmpty
                ? _buildEmptyStateMessage('No categories available')
                : SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return _buildCategoryItem(category, index);
                      },
                    ),
                  ),
      ],
    );
  }
  
  Widget _buildCategoryLoadingShimmer() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: AppColors.surfaceColor,
            highlightColor: AppColors.cardColor,
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildCategoryItem(Category category, int index) {
    // Get a vibrant color based on index for category display
    final List<Color> categoryColors = [
      AppColors.accentTeal,
      AppColors.accentOrange,
      AppColors.accentMagenta,
      AppColors.accentCyan,
      AppColors.accentLime,
      AppColors.primaryColor,
      AppColors.accentPink,
      AppColors.accentYellow,
    ];
    
    final color = categoryColors[index % categoryColors.length];
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(category: category),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(category.name),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ).animate(controller: _controller)
      .fadeIn(
        delay: Duration(milliseconds: 800 + (index * 50)), 
        duration: 300.ms,
      );
  }
  
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    
    if (name.contains('food') || name.contains('restaurant')) {
      return Icons.restaurant;
    } else if (name.contains('tech') || name.contains('electronic')) {
      return Icons.devices;
    } else if (name.contains('fashion') || name.contains('cloth')) {
      return Icons.shopping_bag;
    } else if (name.contains('travel') || name.contains('hotel')) {
      return Icons.flight;
    } else if (name.contains('book') || name.contains('education')) {
      return Icons.book;
    } else if (name.contains('beauty') || name.contains('health')) {
      return Icons.spa;
    } else if (name.contains('entertainment') || name.contains('movie')) {
      return Icons.movie;
    } else if (name.contains('home') || name.contains('furniture')) {
      return Icons.home;
    } else {
      return Icons.local_offer;
    }
  }
  
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 22,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ).animate(controller: _controller)
      .fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms);
  }
  
  Widget _buildEmptyStateMessage(String message) {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox,
              size: 48,
              color: AppColors.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    ).animate(controller: _controller)
      .fadeIn(duration: 300.ms);
  }

  Widget _buildDiscountCard(Discount discount, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiscountDetailScreen(
              discount: discount,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Discount image or placeholder
            Container(
              height: 100,
              width: 160,
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: discount.imageUrl != null && discount.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: discount.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentMagenta),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.local_offer,
                        color: AppColors.accentMagenta,
                        size: 40,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.local_offer,
                    color: AppColors.accentMagenta,
                    size: 40,
                  ),
            ),
            const SizedBox(height: 8),
            // Discount title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                discount.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ).animate(controller: _controller)
      .fadeIn(
        delay: Duration(milliseconds: 400 + (index * 50)), 
        duration: const Duration(milliseconds: 300),
      );
  }

  // Debug function to directly test discounts
  void _testDiscounts() async {
    try {
      final contentfulService = ContentfulService();
      final discounts = await contentfulService.getDiscounts();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Found ${discounts.length} total discounts')),
      );
      
      // Check for featured flag
      final featuredDiscounts = discounts.where((d) => d.featured).toList();
      
      if (featuredDiscounts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No featured discounts found!', style: TextStyle(color: Colors.red))),
        );
      } else {
        final titles = featuredDiscounts.map((d) => d.title).join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Featured discounts: $titles')),
        );
      }
      
      // Check for your specific discount
      print('All discount titles:');
      for (var d in discounts) {
        print('${d.title} - featured: ${d.featured}, expired: ${d.isExpired}, active: ${d.active}');
      }
      
    } catch (e) {
      print('Error in test: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
} 