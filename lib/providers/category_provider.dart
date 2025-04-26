import 'package:flutter/foundation.dart';
import '../models/category.dart' as app_model;
import '../services/contentful_service.dart';

class CategoryProvider with ChangeNotifier {
  final ContentfulService _contentfulService = ContentfulService();
  List<app_model.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  CategoryProvider() {
    _loadCategories();
  }

  List<app_model.Category> get categories {
    return [..._categories];
  }

  bool get isLoading {
    return _isLoading;
  }

  String? get error {
    return _error;
  }

  Future<void> _loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _contentfulService.getCategories();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  app_model.Category getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      // Return a default category if the requested one is not found
      print('Category with ID $id not found: $e');
      return app_model.Category(
        id: 'default',
        name: 'General',
        description: 'Default category',
      );
    }
  }

  Future<void> refreshCategories() {
    return _loadCategories();
  }

  Future<List<String>> getCategoryNames(List<String> categoryIds) async {
    if (_categories.isEmpty) {
      await _loadCategories();
    }

    List<String> categoryNames = [];
    for (String id in categoryIds) {
      final category = getCategoryById(id);
      categoryNames.add(category.name);
        }
    return categoryNames;
  }
} 