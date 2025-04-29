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
    'Food discounts',
    'Electronics deals',
    'Travel offers',
    'Fashion sales',
    'Restaurant deals',
    'Hotel discounts',
  ];
  
  List<Discount> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  int _retryCount = 0;
  bool _isGridView = false;

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

  Widget _buildSuggestionChip(String suggestion, {bool isRecent = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(
          isRecent ? Icons.history : Icons.search,
          size: 16,
          color: Colors.grey,
        ),
        label: Text(suggestion),
        onPressed: () => _performSearch(suggestion),
        backgroundColor: Theme.of(context).cardColor,
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
        ),
      ).animate()
        .fadeIn(delay: Duration(milliseconds: isRecent ? 100 : 200))
        .slideX(begin: 0.2, end: 0),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ask me anything about discounts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Type your search query...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: () {
                      // TODO: Implement voice search
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _performSearch(_searchController.text),
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            onSubmitted: _performSearch,
          ),
          if (_recentSearches.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Recent Searches',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _recentSearches
                    .map((query) => _buildSuggestionChip(query, isRecent: true))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Suggested Searches',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _suggestedQueries
                  .map((query) => _buildSuggestionChip(query))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsGrid() {
    return GridView.builder(
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
          onTap: () => _navigateToDiscountDetail(_searchResults[index]),
          isGridView: true,
        ).animate()
          .fadeIn(delay: Duration(milliseconds: 100 * index))
          .slideY(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DiscountCard(
            discount: _searchResults[index],
            onTap: () => _navigateToDiscountDetail(_searchResults[index]),
          ).animate()
            .fadeIn(delay: Duration(milliseconds: 100 * index))
            .slideX(begin: 0.2, end: 0),
        );
      },
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
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

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _error!.contains('busy') ? Icons.timer : Icons.error_outline,
              size: 64,
              color: _error!.contains('busy') ? Colors.orange : Colors.red,
            ).animate()
              .scale(duration: const Duration(milliseconds: 300)),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: _error!.contains('busy') ? Colors.orange : Colors.red,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (_error!.contains('busy')) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search with AI'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: AnimatedLoading(
                      animationType: 'loading',
                      size: 150,
                      message: 'AI is analyzing discounts...',
                    ),
                  )
                : _error != null
                    ? _buildErrorWidget()
                    : _searchResults.isEmpty && _searchController.text.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No matching discounts found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ).animate()
                            .fadeIn()
                            .scale()
                        : _searchResults.isEmpty
                            ? const Center(
                                child: AnimatedLoading(
                                  animationType: 'ai',
                                  size: 200,
                                  message: 'Ask me about any discounts!\nI can help you find the best deals based on your preferences',
                                ),
                              )
                            : _isGridView
                                ? _buildResultsGrid()
                                : _buildResultsList(),
          ),
        ],
      ),
    );
  }
} 