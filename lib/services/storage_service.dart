import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/discount.dart';

class StorageService {
  static const String _discountsKey = 'discounts';
  
  // Save discounts to local storage
  Future<bool> saveDiscounts(List<Discount> discounts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final discountsJson = discounts.map((discount) => discount.toMap()).toList();
      final jsonString = jsonEncode(discountsJson);
      
      return await prefs.setString(_discountsKey, jsonString);
    } catch (e) {
      print('Error saving discounts: $e');
      return false;
    }
  }
  
  // Load discounts from local storage
  Future<List<Discount>> loadDiscounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_discountsKey);
      
      if (jsonString == null) {
        return [];
      }
      
      final List<dynamic> discountsJson = jsonDecode(jsonString);
      return discountsJson
          .map((json) => Discount.fromMap(json))
          .toList();
    } catch (e) {
      print('Error loading discounts: $e');
      return [];
    }
  }
  
  // Clear all discounts from local storage
  Future<bool> clearDiscounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_discountsKey);
    } catch (e) {
      print('Error clearing discounts: $e');
      return false;
    }
  }
  
  // Save a single setting
  Future<bool> saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (value is String) {
        return await prefs.setString(key, value);
      } else if (value is int) {
        return await prefs.setInt(key, value);
      } else if (value is bool) {
        return await prefs.setBool(key, value);
      } else if (value is double) {
        return await prefs.setDouble(key, value);
      } else {
        return await prefs.setString(key, jsonEncode(value));
      }
    } catch (e) {
      print('Error saving setting: $e');
      return false;
    }
  }
  
  // Get a single setting
  Future<dynamic> getSetting(String key, dynamic defaultValue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (!prefs.containsKey(key)) {
        return defaultValue;
      }
      
      if (defaultValue is String) {
        return prefs.getString(key) ?? defaultValue;
      } else if (defaultValue is int) {
        return prefs.getInt(key) ?? defaultValue;
      } else if (defaultValue is bool) {
        return prefs.getBool(key) ?? defaultValue;
      } else if (defaultValue is double) {
        return prefs.getDouble(key) ?? defaultValue;
      } else {
        final value = prefs.getString(key);
        if (value == null) return defaultValue;
        return jsonDecode(value);
      }
    } catch (e) {
      print('Error getting setting: $e');
      return defaultValue;
    }
  }
} 