import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/category.dart';
import '../models/store.dart';
import '../models/discount.dart';
import '../utils/location_helper.dart';

class ContentfulService {
  final String spaceId;
  final String accessToken;
  final String environment;
  final String baseUrl = 'https://cdn.contentful.com';
  final bool useMockData;

  // Hardcoded values as fallback
  static const String hardcodedSpaceId = 'dm9oug4ckfgv';
  static const String hardcodedAccessToken = 'Unp4wnUCiGanzC64e_9TyzucoF53yyFvmQ42sOt68O0';

  static final ContentfulService _instance = ContentfulService._internal(
    spaceId: _getEnvOrEmpty('CONTENTFUL_SPACE_ID'),
    accessToken: _getEnvOrEmpty('CONTENTFUL_ACCESS_TOKEN'),
    environment: _getEnvOrEmpty('CONTENTFUL_ENVIRONMENT', defaultValue: 'master'),
  );

  factory ContentfulService({
    String? spaceId,
    String? accessToken,
    String? environment,
  }) {
    // If custom credentials are provided, create a new instance
    if (spaceId != null || accessToken != null || environment != null) {
      return ContentfulService._internal(
        spaceId: spaceId ?? _getEnvOrEmpty('CONTENTFUL_SPACE_ID'),
        accessToken: accessToken ?? _getEnvOrEmpty('CONTENTFUL_ACCESS_TOKEN'),
        environment: environment ?? _getEnvOrEmpty('CONTENTFUL_ENVIRONMENT', defaultValue: 'master'),
      );
    }
    // Otherwise use the singleton instance
    return _instance;
  }

  ContentfulService._internal({
    required this.spaceId,
    required this.accessToken,
    required this.environment,
  }) : useMockData = _shouldUseMockData() {
    
    // Log actual values being used (masking the access token for security)
    print('ContentfulService initialized with:');
    print('- Space ID: ${spaceId.isNotEmpty ? spaceId : "NOT SET"}');
    print('- Access Token: ${accessToken.isNotEmpty ? "***" : "NOT SET"}');
    print('- Environment: $environment');
    
    if (spaceId.isEmpty || accessToken.isEmpty) {
      print('WARNING: ContentfulService requires both spaceId and accessToken. Some functionality will be limited.');
    }
  }
  
  // Helper method to safely access environment variables
  static String _getEnvOrEmpty(String key, {String defaultValue = ''}) {
    try {
      // Check if dotenv is available and initialized
      final value = dotenv.env[key];
      print('Loaded env variable $key: ${value != null ? "Success" : "Not found"}');
      return value ?? defaultValue;
    } catch (e) {
      print('Error accessing env variable $key: $e');
      // If there's an error (like dotenv not being initialized),
      // return the default value
      return defaultValue;
    }
  }
  
  // Determine if we should use mock data
  static bool _shouldUseMockData() {
    return false;
  }

  Future<Map<String, dynamic>> _get(String endpoint, {Map<String, String>? queryParams}) async {
    // Use hardcoded values if configured values are empty
    final effectiveSpaceId = spaceId.isEmpty ? hardcodedSpaceId : spaceId.replaceAll('`', '');
    final effectiveAccessToken = accessToken.isEmpty ? hardcodedAccessToken : accessToken.replaceAll('`', '');
    
    if (effectiveSpaceId.isEmpty || effectiveAccessToken.isEmpty) {
      print('WARNING: Using mock data because Contentful credentials are still missing');
      return _getMockData(endpoint, queryParams);
    }
    
    if (useMockData) {
      return _getMockData(endpoint, queryParams);
    }
    
    final params = {
      'access_token': effectiveAccessToken,
      ...?queryParams,
    };

    final uri = Uri.https('cdn.contentful.com', '/spaces/$effectiveSpaceId/environments/$environment/$endpoint', params);
    
    try {
      print('Fetching from Contentful: $uri');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Contentful API success for: $endpoint');
        return json.decode(response.body);
      } else {
        print('API error: ${response.statusCode} ${response.body}');
        print('Falling back to mock data due to API error');
        return _getMockData(endpoint, queryParams);
      }
    } catch (e) {
      print('Network error: $e');
      print('Falling back to mock data due to network error');
      return _getMockData(endpoint, queryParams);
    }
  }
  
  // Generate mock data when Contentful credentials are not available
  Map<String, dynamic> _getMockData(String endpoint, Map<String, String>? queryParams) {
    if (endpoint.contains('entries') && queryParams != null) {
      final contentType = queryParams['content_type'] ?? '';
      
      if (contentType == 'category') {
        return _getMockCategories();
      } else if (contentType == 'store') {
        return _getMockStores();
      } else if (contentType == 'discount') {
        return _getMockDiscounts();
      }
    }
    
    // Default empty response
    return {'items': []};
  }
  
  Map<String, dynamic> _getMockCategories() {
    return {
      'items': [
        {
          'sys': {'id': 'cat1'},
          'fields': {
            'name': 'Restaurants',
            'description': 'Discounts for restaurants and cafes',
            'featured': true,
          }
        },
        {
          'sys': {'id': 'cat2'},
          'fields': {
            'name': 'Electronics',
            'description': 'Deals on tech gadgets and electronics',
            'featured': true,
          }
        },
        {
          'sys': {'id': 'cat3'},
          'fields': {
            'name': 'Fashion',
            'description': 'Clothing and accessory discounts',
            'featured': true,
          }
        }
      ]
    };
  }
  
  Map<String, dynamic> _getMockStores() {
    return {
      'items': [
        {
          'sys': {'id': 'store1'},
          'fields': {
            'name': 'Digital World',
            'description': 'The latest electronics and gadgets',
            'featured': true,
            'categories': [
              {'sys': {'id': 'cat2'}}
            ],
          }
        },
        {
          'sys': {'id': 'store2'},
          'fields': {
            'name': 'Gourmet Kitchen',
            'description': 'Delicious food at affordable prices',
            'featured': true,
            'categories': [
              {'sys': {'id': 'cat1'}}
            ],
          }
        },
        {
          'sys': {'id': 'store3'},
          'fields': {
            'name': 'Style Avenue',
            'description': 'Trendy fashion for everyone',
            'featured': true,
            'categories': [
              {'sys': {'id': 'cat3'}}
            ],
          }
        }
      ]
    };
  }
  
  Map<String, dynamic> _getMockDiscounts() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final nextWeek = now.add(const Duration(days: 7));
    final nextMonth = now.add(const Duration(days: 30));
    
    return {
      'items': [
        {
          'sys': {'id': 'disc1'},
          'fields': {
            'title': 'Limited Time Offer',
            'description': 'Special discount for app users',
            'discountPercentage': 15,
            'code': 'APP15',
            'store': {'sys': {'id': 'store1'}},
            'category': {'sys': {'id': 'cat2'}},
            'expiryDate': nextMonth.toIso8601String(),
            'featured': true,
            'active': true,
          }
        },
        {
          'sys': {'id': 'disc2'},
          'fields': {
            'title': 'New User Special',
            'description': 'Discount for new customers',
            'discountPercentage': 10,
            'code': 'NEWUSER10',
            'store': {'sys': {'id': 'store2'}},
            'category': {'sys': {'id': 'cat1'}},
            'expiryDate': nextWeek.toIso8601String(),
            'featured': true,
            'active': true,
          }
        },
        {
          'sys': {'id': 'disc3'},
          'fields': {
            'title': 'Flash Sale',
            'description': 'One day only special offer',
            'discountPercentage': 20,
            'code': 'FLASH20',
            'store': {'sys': {'id': 'store3'}},
            'category': {'sys': {'id': 'cat3'}},
            'expiryDate': tomorrow.toIso8601String(),
            'featured': true,
            'active': true,
          }
        }
      ]
    };
  }

  Future<List<Category>> getCategories() async {
    final data = await _get('entries', queryParams: {
      'content_type': 'category',
    });

    final List<Category> categories = [];
    
    if (data.containsKey('items')) {
      for (var item in data['items']) {
        try {
          categories.add(Category.fromContentful(item));
        } catch (e) {
          print('Error parsing category: $e');
        }
      }
    }
    
    return categories;
  }

  Future<List<Store>> getStores({String? categoryId}) async {
    final queryParams = {
      'content_type': 'store',
      'include': '3', // Increase include depth to ensure linked assets are retrieved
    };
    
    if (categoryId != null) {
      queryParams['fields.categories.sys.id'] = categoryId;
    }

    print('Fetching stores with params: $queryParams');
    final data = await _get('entries', queryParams: queryParams);
    
    final List<Store> stores = [];
    
    // Check for includes first
    if (data.containsKey('includes')) {
      print('Includes found in Contentful response: ${data['includes'].keys}');
      
      if (data['includes'] is Map && data['includes'].containsKey('Asset')) {
        final assets = data['includes']['Asset'];
        print('Found ${assets.length} assets in includes');
        
        // Print sample asset structure
        if (assets.isNotEmpty) {
          print('Sample asset structure: ${assets.first}');
        }
      }
    } else {
      print('No includes found in Contentful response');
    }
    
    if (data.containsKey('items')) {
      print('Found ${data['items'].length} stores in Contentful response');
      
      for (var item in data['items']) {
        try {
          // Log raw store data for debugging
          print('Processing store: ${item['fields']['name']}');
          if (item['fields'].containsKey('logo')) {
            print('  - Logo data: ${item['fields']['logo']}');
          } else {
            print('  - No logo field found');
          }
          
          if (item['fields'].containsKey('location')) {
            print('  - Location data: ${item['fields']['location']}');
          } else {
            print('  - No location data found');
          }
          
          final store = Store.fromContentful(item);
          print('  - Store ID: ${store.id}, Name: ${store.name}, hasLocation: ${store.hasLocation}, hasLogo: ${store.logoUrl != null}');
          if (store.hasLocation) {
            print('  - Coordinates: ${store.latitude}, ${store.longitude}');
          }
          if (store.logoUrl != null) {
            print('  - Logo URL: ${store.logoUrl}');
          }
          
          stores.add(store);
        } catch (e) {
          print('Error parsing store: $e');
          print('Raw store data: ${item['fields']}');
        }
      }
    } else {
      print('No stores found in Contentful response');
    }
    
    // Log stores with locations
    final storesWithLocation = stores.where((store) => store.hasLocation).toList();
    print('Found ${stores.length} total stores, ${storesWithLocation.length} with valid location data');
    
    // Log stores with logos
    final storesWithLogos = stores.where((store) => store.logoUrl != null).toList();
    print('Found ${storesWithLogos.length} stores with valid logo images');
    
    return stores;
  }
  
  // Get stores within a specified radius of a location
  Future<List<Store>> getNearbyStores(LatLng location, {double radiusKm = 10.0}) async {
    final stores = await getStores();
    
    // Filter stores with location data and within radius
    final nearbyStores = stores.where((store) {
      if (!store.hasLocation) return false;
      
      final storeLocation = LatLng(store.latitude!, store.longitude!);
      final distance = LocationHelper.calculateDistance(location, storeLocation);
      
      return distance <= radiusKm;
    }).toList();
    
    // Sort by distance
    nearbyStores.sort((a, b) {
      final locationA = LatLng(a.latitude!, a.longitude!);
      final locationB = LatLng(b.latitude!, b.longitude!);
      
      final distanceA = LocationHelper.calculateDistance(location, locationA);
      final distanceB = LocationHelper.calculateDistance(location, locationB);
      
      return distanceA.compareTo(distanceB);
    });
    
    return nearbyStores;
  }

  Future<List<Discount>> getDiscounts({String? storeId, String? categoryId, bool? featured}) async {
    final queryParams = {
      'content_type': 'discount',
      'include': '2', // Include linked assets (like images) in the response
    };
    
    if (storeId != null) {
      queryParams['fields.store.sys.id'] = storeId;
    }
    
    if (categoryId != null) {
      queryParams['fields.category.sys.id'] = categoryId;
    }
    
    // We can't rely on Contentful's query for featured because of how the data might be stored
    // We'll filter after retrieval instead
    print('Fetching discounts from Contentful with params: $queryParams');

    final data = await _get('entries', queryParams: queryParams);
    
    final List<Discount> discounts = [];
    
    // Process the includes to make image lookup easier
    Map<String, dynamic> assetsMap = {};
    if (data.containsKey('includes') && 
        data['includes'] is Map && 
        data['includes'].containsKey('Asset')) {
      final assets = data['includes']['Asset'];
      print('Found ${assets.length} asset includes');
      for (var asset in assets) {
        if (asset.containsKey('sys') && asset['sys'].containsKey('id')) {
          assetsMap[asset['sys']['id']] = asset;
        }
      }
    } else {
      print('No asset includes found in response. Includes keys: ${data.containsKey('includes') ? (data['includes'] is Map ? (data['includes'] as Map).keys.toList() : 'includes not a map') : 'no includes key'}');
    }
    
    if (data.containsKey('items')) {
      final items = data['items'];
      print('Processing ${items.length} discounts from Contentful');
      
      for (var item in items) {
        try {
          // Check if the discount has an image and process it
          if (item['fields'].containsKey('image') && 
              item['fields']['image'] is Map && 
              item['fields']['image'].containsKey('sys')) {
            final imageId = item['fields']['image']['sys']['id'];
            if (assetsMap.containsKey(imageId)) {
              // Replace the image reference with the actual asset data
              item['fields']['image'] = assetsMap[imageId];
              print('Processed image for discount: ${item['fields']['title']}');
            } else {
              print('Image asset not found for ID: $imageId');
            }
          }
          
          // Manually check the featured flag
          final fields = item['fields'] as Map<String, dynamic>? ?? {};
          final featuredValue = fields['featured'];
          final title = fields['title'] ?? 'Unnamed';
          
          // Print raw data for debugging
          print('Raw discount data for $title: featured = $featuredValue (${featuredValue.runtimeType})');
          
          final discount = Discount.fromContentful(item);
          print('Successfully parsed discount: ${discount.title} (featured=${discount.featured})');
          
          // Only add if it matches the featured filter (if specified)
          if (featured == null || discount.featured == featured) {
            discounts.add(discount);
          }
        } catch (e) {
          print('Error parsing discount: $e');
          if (item.containsKey('fields')) {
            print('Discount data: ${item['fields']}');
          } else {
            print('No fields in item: $item');
          }
        }
      }
    } else {
      print('No items found in Contentful response. Keys: ${data.keys.toList()}');
    }
    
    print('Returning ${discounts.length} discounts (featured filter: $featured)');
    return discounts;
  }
  
  // Get featured discounts specifically
  Future<List<Discount>> getFeaturedDiscounts() async {
    print('Getting featured discounts directly');
    
    // Try to fetch with the featured parameter directly
    try {
      // First try directly with a featured=true parameter
      final queryParams = {
        'content_type': 'discount',
        'include': '2',
        'fields.featured': 'true', // Try to filter on the server side
      };
      
      print('Fetching directly with fields.featured=true');
      final uri = Uri.https('cdn.contentful.com', 
        '/spaces/$spaceId/environments/$environment/entries', 
        {...queryParams, 'access_token': accessToken});
      print('Fetching from URL: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Direct featured query returned ${data.containsKey('items') ? data['items'].length : 0} items');
        
        final List<Discount> discounts = [];
        if (data.containsKey('items') && data['items'].isNotEmpty) {
          // Process the items
          for (var item in data['items']) {
            try {
              final discount = Discount.fromContentful(item);
              if (!discount.isExpired && discount.active) {
                discounts.add(discount);
              }
            } catch (e) {
              print('Error parsing featured discount: $e');
            }
          }
        }
        
        if (discounts.isNotEmpty) {
          print('Found ${discounts.length} featured discounts via direct query');
          return discounts;
        }
      }
    } catch (e) {
      print('Error in direct featured query: $e');
    }
    
    // Fallback to getting all discounts and filtering client-side
    print('Falling back to get all discounts and filter for featured=true');
    final discounts = await getDiscounts();
    final featuredDiscounts = discounts.where((d) => d.featured && !d.isExpired && d.active).toList();
    print('Found ${featuredDiscounts.length} featured discounts from ${discounts.length} total via fallback');
    
    // Print them for debugging
    if (featuredDiscounts.isNotEmpty) {
      print('Featured discounts:');
      for (var d in featuredDiscounts) {
        print('- ${d.title} (featured: ${d.featured}, expired: ${d.isExpired}, active: ${d.active})');
      }
    }
    
    return featuredDiscounts;
  }
  
  // Get discounts from stores near a location
  Future<List<Discount>> getNearbyDiscounts(LatLng location, {double radiusKm = 10.0}) async {
    final nearbyStores = await getNearbyStores(location, radiusKm: radiusKm);
    
    if (nearbyStores.isEmpty) {
      return [];
    }
    
    final List<Discount> allDiscounts = [];
    
    // Get discounts for each nearby store
    for (final store in nearbyStores) {
      final storeDiscounts = await getDiscounts(storeId: store.id);
      allDiscounts.addAll(storeDiscounts);
    }
    
    return allDiscounts;
  }

  Future<Discount?> getDiscountById(String id) async {
    try {
      final data = await _get('entries/$id', queryParams: {
        'include': '2', // Include linked assets
      });
      return Discount.fromContentful(data);
    } catch (e) {
      print('Error getting discount by ID: $e');
      return null;
    }
  }
} 