import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/store.dart';
import '../services/contentful_service.dart';

class StoresProvider with ChangeNotifier {
  final ContentfulService _contentfulService = ContentfulService();
  List<Store> _stores = [];
  List<Store> _nearbyStores = [];
  bool _isLoading = false;
  String? _error;

  StoresProvider() {
    loadStores();
  }

  List<Store> get stores => _stores;
  List<Store> get nearbyStores => _nearbyStores;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStores() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stores = await _contentfulService.getStores();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load stores: $e';
      notifyListeners();
    }
  }

  Future<void> updateNearbyStores(LatLng location, {double radiusKm = 10.0}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _nearbyStores = await _contentfulService.getNearbyStores(location, radiusKm: radiusKm);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to update nearby stores: $e';
      notifyListeners();
    }
  }

  Store? getStoreById(String id) {
    try {
      return _stores.firstWhere((store) => store.id == id);
    } catch (e) {
      return null;
    }
  }
} 