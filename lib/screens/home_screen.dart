import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../models/category.dart';
import '../models/store.dart';
import '../models/discount.dart';
import '../services/contentful_service.dart';
import '../utils/app_colors.dart';
import '../utils/animation_utils.dart';
import '../services/auth_service.dart';
import '../components/discount_card.dart';
import '../components/animated_loading.dart';
import 'location_search_screen.dart';
import 'category_search_screen.dart';
import 'discount_detail_screen.dart';
import 'store_detail_screen.dart';
import 'category_detail_screen.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'dart:math' as Math;

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
    
    // Reset animation controller to avoid animation exceptions
    _controller.reset();

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
        
        // Make sure controller is at 0 position before forwarding
        if (!_controller.isAnimating) {
          _controller.reset();
          _controller.forward();
        }
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
      // Use the static instance getter instead of constructing a new instance
      final contentfulService = ContentfulService.instance;
      
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
    // Get current theme mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient - different for dark/light modes
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        AppColors.backgroundColor,
                        Color(0xFF0A1A0F), // Very dark green-black
                        Color(0xFF102213), // Dark green-black
                        Color(0xFF152A18), // Medium dark green
                      ]
                    : [
                        Colors.white,
                        Color(0xFFF8FAF8), // Very light green-white
                        Color(0xFFF5F8F5), // Light green-white 
                        Color(0xFFF0F5F0), // Subtle light green
                      ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),
          // Hexagon pattern overlay
          Opacity(
            opacity: isDarkMode ? 0.04 : 0.08,
            child: Container(
              child: CustomPaint(
                painter: HexagonPatternPainter(
                  color: isDarkMode 
                      ? AppColors.primaryColor.withOpacity(0.4)
                      : AppColors.primaryColor.withOpacity(0.2),
                  hexSize: 40,
                  spacing: 70,
                ),
                child: Container(),
              ),
            ),
          ),
          // Dot pattern overlay
          Opacity(
            opacity: isDarkMode ? 0.05 : 0.07,
            child: Container(
              child: CustomPaint(
                painter: DotPatternPainter(
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.3)
                      : AppColors.primaryColor.withOpacity(0.2),
                  dotSize: 1.0,
                  spacing: 15,
                ),
                child: Container(),
              ),
            ),
          ),
          // Subtle diagonal line overlay
          Opacity(
            opacity: isDarkMode ? 0.02 : 0.04,
            child: Container(
              child: CustomPaint(
                painter: DiagonalLinePainter(
                  color: isDarkMode
                      ? Colors.lightGreen.withOpacity(0.2)
                      : AppColors.primaryColor.withOpacity(0.1),
                  lineWidth: 0.5,
                  spacing: 50,
                ),
                child: Container(),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildAnimatedAppBar(innerBoxIsScrolled, isDarkMode),
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
        ],
      ),
      
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor,
              AppColors.secondaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.3),
              offset: const Offset(0, 3),
              blurRadius: 6,
            )
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            // Use this for testing images
            _testImageLoading();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          tooltip: 'Test Images',
          child: const Icon(Icons.image),
        ),
      ),
    );
  }

  Widget _buildAnimatedAppBar(bool innerBoxIsScrolled, bool isDarkMode) {
    final appBar = SliverAppBar(
      expandedHeight: 80.0,
      floating: true,
      pinned: true,
      snap: true,
      title: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor,
              Color(0xFF388E3C), // Darker green
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.3),
              offset: const Offset(0, 2),
              blurRadius: 6,
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: const Row(
          children: [
            Icon(
              Icons.attach_money,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'Chhar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: isDarkMode ? Colors.white : Colors.white,
              size: 22,
            ),
          ),
          onPressed: () {
            // Navigate to notifications
          },
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.logout,
              color: isDarkMode ? Colors.white : Colors.white,
              size: 22,
            ),
          ),
          onPressed: () async {
            // Sign out using the context provider
            final authService = Provider.of<AuthService>(context, listen: false);
            await authService.signOut();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
    
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
    );
  }
  
  Widget _buildWelcomeHeader() {
    final user = Provider.of<AuthService>(context).currentUser;
    final greeting = _getGreeting();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final container = Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.waving_hand_rounded,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$greeting, ${user?.displayName?.split(' ').first ?? 'User'}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Discover the best deals from your favorite stores',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? AppColors.textSecondaryColor : Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
    
    return container.animate()
      .fadeIn(duration: const Duration(milliseconds: 350))
      .slideY(begin: 0.2, end: 0);
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
          title: 'Search with AI',
          subtitle: 'Find deals using AI assistant',
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final cardWidget = AnimationUtils.withPressEffect(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          height: isLarge ? 130 : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                isDarkMode ? AppColors.cardColor : Colors.white,
                isDarkMode ? AppColors.cardColor : Colors.white,
                color.withOpacity(isDarkMode ? 0.2 : 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: isLarge
              ? Row(
                  children: [
                    // Animated icon
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _buildSearchAnimatedIcon(animationType, color),
                    ),
                    const SizedBox(width: 16),
                    
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? AppColors.textSecondaryColor : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Arrow icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: color,
                        size: 20,
                      ),
                    ),
                  ],
                )
              : const SizedBox(), // We only use the large variant for now
        ),
      ),
    );
    
    return cardWidget.animate(autoPlay: true)
      .fadeIn(
        delay: Duration(milliseconds: delay), 
        duration: const Duration(milliseconds: 300)
      );
  }
  
  Widget _buildSearchAnimatedIcon(String type, Color color) {
    final IconData iconData = type == 'location' 
      ? Icons.location_on_rounded 
      : Icons.search_rounded;
    
    final iconWidget = Icon(
      iconData,
      color: color,
      size: 32,
    );
    
    return iconWidget.animate(
      autoPlay: true,
      onComplete: (controller) => controller.repeat(),
    ).shimmer(
      duration: const Duration(milliseconds: 2000),
      delay: const Duration(milliseconds: 500),
    );
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
                    child: AnimationLimiter(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _featuredStores.length,
                        itemBuilder: (context, index) {
                          final store = _featuredStores[index];
                          return _buildStoreCard(context, store, index);
                        },
                      ),
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

  Widget _buildStoreCard(BuildContext context, Store store, int index) {
    print('Building store card for: ${store.name}, logoUrl: ${store.logoUrl}');
    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 375),
      columnCount: _featuredStores.length,
      child: SlideAnimation(
        horizontalOffset: 50.0,
        child: FadeInAnimation(
          child: AnimationUtils.withPressEffect(
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
                    child: store.logoUrl != null && store.logoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: store.logoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              print('Error loading store image: $error for URL: $url');
                              return const Icon(
                                Icons.store,
                                color: AppColors.accentMagenta,
                                size: 30,
                              );
                            },
                            // Add image format specific handling
                            fadeInDuration: const Duration(milliseconds: 300),
                            memCacheHeight: 140, // Optimize cache size
                            memCacheWidth: 140,
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
          ),
        ),
      ),
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
            AnimationUtils.withPressEffect(
              scale: 0.9,
              onTap: _fetchData,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.refresh,
                  color: AppColors.accentTeal,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _isDiscountsLoading
            ? _buildDiscountLoadingShimmer()
            : AnimationLimiter(
                child: Column(
                  children: List.generate(_featuredDiscounts.length, (index) {
                    final discount = _featuredDiscounts[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DiscountCard(
                              key: ValueKey('discount_${discount.id}'),
                              discount: discount,
                              onTap: () => _navigateToDiscountDetail(discount),
                              showAnimation: true, // Enable animations
                              onFavorite: () {
                                // Handle favorite toggle
                                setState(() {
                                  // Toggle favorite status locally
                                  _featuredDiscounts[index] = discount.copyWith(
                                    isFavorite: !discount.isFavorite,
                                  );
                                });
                                // TODO: Save to backend or shared preferences
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
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
                        return _buildCategoryItem(context, category, index);
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
  
  Widget _buildCategoryItem(BuildContext context, Category category, int index) {
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyStateMessage(String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 48,
              color: isDarkMode ? AppColors.textSecondaryColor : Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? AppColors.textSecondaryColor : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
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
                      imageUrl: discount.imageUrl!.startsWith('http') 
                          ? discount.imageUrl! 
                          : discount.imageUrl!.startsWith('//')
                              ? 'https:${discount.imageUrl!}'
                              : 'https://${discount.imageUrl!}',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        print('Error loading discount image: $error for URL: $url');
                        return const Icon(
                          Icons.local_offer,
                          color: AppColors.accentMagenta,
                          size: 40,
                        );
                      },
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
    );
  }

  // New test method to debug image loading
  void _testImageLoading() async {
    try {
      // Test direct image loading
      const testUrl = 'https://via.placeholder.com/150';
      const snackBar = SnackBar(
        content: Text('Testing image loading from: $testUrl'),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      
      print('Testing image loading capabilities');
      print('Test URL: $testUrl');
      
      // Test Contentful directly to examine store data
      final contentfulService = ContentfulService();
      print('\n=== CONTENTFUL STORE TEST ===');
      final stores = await contentfulService.getStores();
      
      print('Fetched ${stores.length} stores from Contentful');
      for (var store in stores) {
        print('Store: ${store.name}, Logo URL: ${store.logoUrl}');
      }
      
      // Test loading images directly 
      if (stores.isNotEmpty) {
        final storeNames = stores.map((s) => s.name).join(', ');
        final infoSnackBar = SnackBar(
          content: Text('Testing stores: $storeNames'),
          duration: const Duration(seconds: 5),
        );
        ScaffoldMessenger.of(context).showSnackBar(infoSnackBar);
      }
      
      // Also test Contentful connection
      _testDiscounts();
    } catch (e) {
      print('Error in image test: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image test error: $e')),
      );
    }
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
        print('  Image URL: ${d.imageUrl}');
      }
      
    } catch (e) {
      print('Error in test: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

// Dot pattern painter for background effect
class DotPatternPainter extends CustomPainter {
  final Color color;
  final double dotSize;
  final double spacing;

  DotPatternPainter({
    required this.color,
    required this.dotSize,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(
          Offset(i, j),
          dotSize,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Hexagon pattern painter for background effect
class HexagonPatternPainter extends CustomPainter {
  final Color color;
  final double hexSize;
  final double spacing;

  HexagonPatternPainter({
    required this.color,
    required this.hexSize,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        drawHexagon(canvas, Offset(i, j), hexSize, paint);
      }
    }
  }

  void drawHexagon(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const int sides = 6;
    final double angle = (Math.pi * 2) / sides;
    final double startAngle = 0; // starting angle

    // Move to the first point
    path.moveTo(
      center.dx + size * Math.cos(startAngle),
      center.dy + size * Math.sin(startAngle),
    );

    // Draw lines to each corner
    for (int i = 1; i <= sides; i++) {
      double x = center.dx + size * Math.cos(startAngle + angle * i);
      double y = center.dy + size * Math.sin(startAngle + angle * i);
      path.lineTo(x, y);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Diagonal line pattern painter for background effect
class DiagonalLinePainter extends CustomPainter {
  final Color color;
  final double lineWidth;
  final double spacing;

  DiagonalLinePainter({
    required this.color,
    required this.lineWidth,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 