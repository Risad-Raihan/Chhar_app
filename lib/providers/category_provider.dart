import 'package:flutter/foundation.dart';
import '../models/category.dart' as app_model;
import '../services/contentful_service.dart';
import 'package:flutter/material.dart';

class CategoryProvider extends ChangeNotifier {
  final ContentfulService _contentfulService = ContentfulService();
  List<app_model.Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  Map<String, String> _categoryNames = {};
  bool _initialized = false;

  List<app_model.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CategoryProvider() {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (_isLoading || _initialized) return;
    
    _isLoading = true;
    
    try {
      final categories = await _contentfulService.getCategories();
      _categories = categories;
      
      // Create a map of category IDs to names for quick lookup
      _categoryNames = {};
      for (var category in categories) {
        _categoryNames[category.id] = category.name;
      }
      
      _initialized = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get category by ID
  app_model.Category? getCategoryById(String id) {
    return _categories.firstWhere(
      (category) => category.id == id,
      orElse: () => app_model.Category(
        id: id,
        name: 'Unknown',
        description: '',
      ),
    );
  }
  
  // Safe way to get category names without triggering a rebuild during build
  Future<List<String>> getCategoryNames(List<String> ids) async {
    // If the categories aren't loaded yet, load them first
    if (!_initialized && !_isLoading) {
      await _loadCategories();
    }
    
    // If still loading, return placeholders
    if (_isLoading) {
      return List.filled(ids.length, "Loading...");
    }
    
    // Return names for the IDs
    return ids.map((id) => _categoryNames[id] ?? 'Category').toList();
  }
  
  // Synchronous version for use in build methods
  List<String> getCategoryNamesSync(List<String> ids) {
    if (_categoryNames.isEmpty) {
      // Schedule loading but don't wait for it
      Future.microtask(() => _loadCategories());
      return List.filled(ids.length, "Category");
    }
    
    return ids.map((id) => _categoryNames[id] ?? 'Category').toList();
  }
  
  // Refresh categories
  void refreshCategories() {
    _initialized = false;
    _loadCategories();
  }
} 