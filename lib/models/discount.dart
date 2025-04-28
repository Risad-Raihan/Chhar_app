import 'package:intl/intl.dart';

class Discount {
  final String id;
  final String title;
  final String? description;
  final double discountPercentage;
  final String? code;
  final String storeId;
  final String categoryId;
  final DateTime expiryDate;
  final String? imageUrl;
  final bool featured;
  final bool active;
  final bool isFavorite;
  final String? fullDescription;
  final String? storeLogoUrl;

  // Add these getters for backward compatibility
  String get store => storeId;
  String get category => categoryId;
  
  // Add a getter to get description from fullDescription if description is null
  String get displayDescription => description ?? fullDescription ?? '';

  Discount({
    required this.id,
    required this.title,
    this.description,
    required this.discountPercentage,
    this.code,
    required this.storeId,
    required this.categoryId,
    required this.expiryDate,
    this.imageUrl,
    required this.featured,
    required this.active,
    this.isFavorite = false,
    this.fullDescription,
    this.storeLogoUrl,
  });

  String get formattedExpiryDate {
    return DateFormat.yMMMd().format(expiryDate);
  }

  int get daysLeft {
    return expiryDate.difference(DateTime.now()).inDays;
  }

  // isExpired is used as both a property and a method in the app
  // Access this directly for both cases
  bool get isExpired {
    return DateTime.now().isAfter(expiryDate);
  }

  // Method to get days remaining
  int daysRemaining() {
    return daysLeft;
  }

  factory Discount.fromContentful(Map<String, dynamic> entry, [Map<String, dynamic>? includes]) {
    final fields = entry['fields'] as Map<String, dynamic>;
    final id = entry['sys']['id'];
    
    // Extract store ID
    String? storeId;
    if (fields.containsKey('store') && fields['store'] is Map && 
        fields['store'].containsKey('sys') && fields['store']['sys'] is Map &&
        fields['store']['sys'].containsKey('id')) {
      storeId = fields['store']['sys']['id'];
    }
    
    // Extract category ID
    String? categoryId;
    if (fields.containsKey('category') && fields['category'] is Map && 
        fields['category'].containsKey('sys') && fields['category']['sys'] is Map &&
        fields['category']['sys'].containsKey('id')) {
      categoryId = fields['category']['sys']['id'];
    }
    
    // Extract image URL
    String? imageUrl;
    if (fields.containsKey('image') && fields['image'] != null) {
      final image = fields['image'];
      
      // Handle direct URL string
      if (image is String) {
        imageUrl = image;
      } 
      // Handle asset reference
      else if (image is Map && image.containsKey('sys') && image['sys'] is Map && image['sys'].containsKey('id')) {
        final assetId = image['sys']['id'];
        
        if (includes != null && includes.containsKey('Asset') && includes['Asset'] is List) {
          final assets = includes['Asset'] as List;
          
          try {
            for (var asset in assets) {
              if (asset is Map && 
                  asset.containsKey('sys') && 
                  asset['sys'] is Map && 
                  asset['sys']['id'] == assetId) {
                
                if (asset.containsKey('fields') &&
                    asset['fields'] is Map &&
                    asset['fields'].containsKey('file') &&
                    asset['fields']['file'] is Map &&
                    asset['fields']['file'].containsKey('url')) {
                  imageUrl = asset['fields']['file']['url'];
                  print('Processed image for discount: ${fields['title']}');
                  break;
                }
              }
            }
          } catch (e) {
            print('Error processing image for discount: $e');
          }
        }
      }
    }
    
    // Format URL
    if (imageUrl != null && imageUrl.startsWith('//')) {
      imageUrl = 'https:$imageUrl';
    }
    
    // Handle featured flag
    bool featured = false;
    if (fields.containsKey('featured')) {
      try {
        final featuredRaw = fields['featured'];
        print('Raw discount data for ${fields['title']}: featured = $featuredRaw (${featuredRaw.runtimeType})');
        
        if (featuredRaw is bool) {
          featured = featuredRaw;
          print('Featured value raw: $featuredRaw (bool)');
        } else if (featuredRaw is String) {
          featured = featuredRaw.toLowerCase() == 'true';
          print('Featured value raw: $featuredRaw (String)');
        } else if (featuredRaw is num) {
          featured = featuredRaw > 0;
          print('Featured value raw: $featuredRaw (num)');
        }
        
        print('Final featured flag value: $featured');
      } catch (e) {
        print('Error parsing featured flag: $e');
      }
    }
    
    // Handle active flag
    bool active = true; // Default to active
    if (fields.containsKey('active')) {
      try {
        final activeRaw = fields['active'];
        
        if (activeRaw is bool) {
          active = activeRaw;
        } else if (activeRaw is String) {
          active = activeRaw.toLowerCase() == 'true';
        } else if (activeRaw is num) {
          active = activeRaw > 0;
        }
      } catch (e) {
        print('Error parsing active flag: $e');
      }
    }
    
    // Parse expiry date
    DateTime? expiryDate;
    if (fields.containsKey('expiryDate') && fields['expiryDate'] != null) {
      try {
        if (fields['expiryDate'] is String) {
          expiryDate = DateTime.parse(fields['expiryDate']);
        }
      } catch (e) {
        print('Error parsing expiry date: $e');
      }
    }
    
    print('Parsed discount ${fields['title']}: featured=$featured, active=$active, storeId=$storeId, categoryId=$categoryId');
    
    final discount = Discount(
      id: id,
      title: fields['title'] ?? '',
      description: fields['description'],
      discountPercentage: _extractNumber(fields['discountPercentage']),
      code: fields['code'],
      storeId: storeId ?? '',
      categoryId: categoryId ?? '',
      expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      imageUrl: imageUrl,
      featured: featured,
      active: active,
      fullDescription: fields['fullDescription'],
      storeLogoUrl: fields['storeLogoUrl'],
    );
    
    if (discount.featured) {
      print('Successfully parsed discount: ${discount.title} (featured=true)');
    }
    
    return discount;
  }

  // Copy with method for creating a new instance with updated values
  Discount copyWith({
    String? id,
    String? title,
    String? description,
    double? discountPercentage,
    String? code,
    String? storeId,
    String? categoryId,
    DateTime? expiryDate,
    String? imageUrl,
    bool? featured,
    bool? active,
    bool? isFavorite,
    String? fullDescription,
    String? storeLogoUrl,
  }) {
    return Discount(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      code: code ?? this.code,
      storeId: storeId ?? this.storeId,
      categoryId: categoryId ?? this.categoryId,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      featured: featured ?? this.featured,
      active: active ?? this.active,
      isFavorite: isFavorite ?? this.isFavorite,
      fullDescription: fullDescription ?? this.fullDescription,
      storeLogoUrl: storeLogoUrl ?? this.storeLogoUrl,
    );
  }

  // Convert to Map for storage/serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'discountPercentage': discountPercentage,
      'code': code,
      'storeId': storeId,
      'categoryId': categoryId,
      'expiryDate': expiryDate.millisecondsSinceEpoch,
      'imageUrl': imageUrl,
      'featured': featured,
      'active': active,
      'isFavorite': isFavorite,
      'fullDescription': fullDescription,
      'storeLogoUrl': storeLogoUrl,
    };
  }

  // Create from Map for deserialization
  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      discountPercentage: map['discountPercentage'],
      code: map['code'],
      storeId: map['storeId'],
      categoryId: map['categoryId'],
      expiryDate: DateTime.fromMillisecondsSinceEpoch(map['expiryDate']),
      imageUrl: map['imageUrl'],
      featured: map['featured'],
      active: map['active'],
      isFavorite: map['isFavorite'] ?? false,
      fullDescription: map['fullDescription'],
      storeLogoUrl: map['storeLogoUrl'],
    );
  }

  // Helper method to extract numeric values
  static double _extractNumber(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    
    return 0.0;
  }
} 