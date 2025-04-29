import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/ai_search_service.dart';
import '../models/discount.dart';
import '../components/discount_card.dart';
import '../components/animated_loading.dart';
import 'discount_detail_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CategorySearchScreen extends StatefulWidget {
  const CategorySearchScreen({Key? key}) : super(key: key);

  @override
  State<CategorySearchScreen> createState() => _CategorySearchScreenState();
}

class _CategorySearchScreenState extends State<CategorySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AISearchService _aiSearchService = AISearchService();
  final List<String> _recentSearches = [];
  final List<String> _suggestedQueries = [
    'Travel discounts',
    'Transport offers',
    'Laptop deals',
    'Tech offers',
    'Hotel discounts',
    'Flight deals',
  ];
  
  List<Discount> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  int _retryCount = 0;
  bool _isGridView = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    // TODO: Implement local storage for recent searches
    setState(() {
      _recentSearches.clear();
    });
  }

  void _saveSearch(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      if (_recentSearches.contains(query)) {
        _recentSearches.remove(query);
      }
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    });
    // TODO: Save to local storage
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

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _hasSearched = false;
      _error = null;
      _isLoading = false;
    });
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: _performSearch,
        decoration: InputDecoration(
          hintText: 'Ask me about discounts...',
          prefixIcon: const Icon(Icons.search, color: AppColors.accentTeal),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.mic, color: AppColors.accentMagenta),
                onPressed: () {
                  // TODO: Implement voice search
                },
              ),
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                color: AppColors.accentTeal,
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Text(
              'Recent Searches',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches
                  .map((query) => _buildSuggestionChip(query, isRecent: true))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Popular Categories',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedQueries
                .map((query) => _buildSuggestionChip(query))
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Search Tips',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Try searching for specific stores like "Lenovo" or "ShareTrip"\n'
            '• Search for discount types like "rewards" or "offers"\n'
            '• Look for travel services like "flights" or "hotels"\n'
            '• Search for tech products like "laptop" or "electronics"',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion, {bool isRecent = false}) {
    return ActionChip(
      avatar: Icon(
        isRecent ? Icons.history : Icons.search,
        size: 16,
        color: AppColors.accentTeal,
      ),
      label: Text(suggestion),
      labelStyle: TextStyle(
        color: isRecent ? Colors.grey[600] : AppColors.accentTeal,
      ),
      backgroundColor: isRecent 
          ? Colors.grey.withOpacity(0.1)
          : AppColors.accentTeal.withOpacity(0.1),
      onPressed: () => _performSearch(suggestion),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: isRecent ? 100 : 200))
      .slideX(begin: 0.2, end: 0);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AnimatedLoading(
            animationType: 'loading',
            size: 150,
            message: 'AI is analyzing discounts...',
          ),
          const SizedBox(height: 24),
          Text(
            'Finding the best matches for you...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                _performSearch(_searchController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (!_hasSearched) {
      return const Center(
        child: AnimatedLoading(
          animationType: 'ai',
          size: 200,
          message: 'Ask me about any discounts!\nI can help you find the best deals based on your preferences',
        ),
      );
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No matching discounts found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or check out our suggestions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn()
      .scale();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      print('Starting search for query: $query');
      final results = await _aiSearchService.searchDiscounts(query);
      print('Search completed. Found ${results.length} results');
      
      _saveSearch(query);
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
        _retryCount = 0;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        if (e.toString().contains('overloaded') && _retryCount < 3) {
          _error = 'AI service is busy. Retrying in a moment...';
          _retryCount++;
          Future.delayed(Duration(seconds: 2 * _retryCount), () {
            if (mounted) {
              _performSearch(query);
            }
          });
        } else {
          _error = e.toString().replaceAll('Exception: ', '');
          _retryCount = 0;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AppBar(
                title: const Text('Search with AI'),
                elevation: 0,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      color: AppColors.accentTeal,
                      tooltip: 'Refresh page',
                      onPressed: _clearSearch,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: AppColors.accentMagenta.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.info_outline),
                      color: AppColors.accentMagenta,
                      tooltip: 'Search tips',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('AI Search Tips'),
                            content: const Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• Ask natural questions about discounts'),
                                Text('• Specify categories or preferences'),
                                Text('• Mention price ranges or percentages'),
                                Text('• Ask about specific stores or brands'),
                                Text('• Filter by expiration dates'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Got it'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : _searchResults.isEmpty
                          ? SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildSuggestionsSection(),
                                  if (_hasSearched) _buildEmptyState(),
                                ],
                              ),
                            )
                          : _isGridView
                              ? GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    return DiscountCard(
                                      discount: _searchResults[index],
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DiscountDetailScreen(
                                            discount: _searchResults[index],
                                          ),
                                        ),
                                      ),
                                      isGridView: true,
                                    ).animate()
                                      .fadeIn(delay: Duration(milliseconds: 100 * index))
                                      .slideY(begin: 0.2, end: 0);
                                  },
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: DiscountCard(
                                        discount: _searchResults[index],
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DiscountDetailScreen(
                                              discount: _searchResults[index],
                                            ),
                                          ),
                                        ),
                                      ).animate()
                                        .fadeIn(delay: Duration(milliseconds: 100 * index))
                                        .slideX(begin: 0.2, end: 0),
                                    );
                                  },
                                ),
            ),
          ],
        ),
      ),
    );
  }
} 