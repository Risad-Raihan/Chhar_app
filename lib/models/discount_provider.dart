import 'package:flutter/foundation.dart';
import 'discount.dart';

class DiscountProvider with ChangeNotifier {
  List<Discount> _discounts = [];
  final List<String> _categories = ['All', 'Food', 'Fashion', 'Electronics', 'Travel', 'Beauty', 'Entertainment', 'Health'];
  
  // Getters
  List<Discount> get discounts => _discounts;
  List<String> get categories => [..._categories];
  
  // Get favorite discounts
  List<Discount> get favoriteDiscounts => 
      _discounts.where((discount) => discount.isFavorite).toList();
  
  // Add discount
  void addDiscount(Discount discount) {
    _discounts.add(discount);
    notifyListeners();
  }
  
  // Remove discount
  void removeDiscount(String id) {
    _discounts.removeWhere((discount) => discount.id == id);
    notifyListeners();
  }
  
  // Get discounts by category
  List<Discount> getDiscountsByCategory(String category) {
    if (category == 'All') return _discounts;
    return _discounts.where((discount) => discount.category == category).toList();
  }
  
  // Toggle favorite
  void toggleFavorite(String id) {
    final index = _discounts.indexWhere((discount) => discount.id == id);
    if (index >= 0) {
      _discounts[index] = _discounts[index].copyWith(isFavorite: !_discounts[index].isFavorite);
      notifyListeners();
    }
  }
  
  // Load mock data for testing
  void loadMockData() {
    _discounts = List.generate(
      10,
      (index) => Discount(
        id: 'discount_$index',
        title: 'Discount ${index + 1}',
        description: 'This is a description for discount ${index + 1}',
        discountPercentage: (index + 1) * 5.0,
        code: 'CODE${index + 1}',
        storeId: 'Store ${index % 5 + 1}',
        categoryId: _categories[(index % 7) + 1], // Skip 'All'
        expiryDate: DateTime.now().add(Duration(days: 7 * (index + 1))),
        imageUrl: 'https://via.placeholder.com/150',
        featured: index < 5,
        active: true,
        isFavorite: index % 3 == 0,
      ),
    );
    notifyListeners();
  }
} 