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

  factory Discount.fromContentful(Map<String, dynamic> entry) {
    final fields = entry['fields'] as Map<String, dynamic>;
    final id = entry['sys']?['id'] as String? ?? '';
    
    // Check for mock data by ID or titles
    if (id == 'disc1' || id == 'disc2' || id == 'disc3') {
      throw Exception('Refusing to create discount from mock data (mock ID detected)');
    }
    
    final title = fields['title'] as String? ?? '';
    if (title == 'Flash Sale' || title == 'New User Special' || title == 'Limited Time Offer') {
      // These are known mock data titles
      throw Exception('Refusing to create discount from suspected mock data (title: $title)');
    }
    
    // Required fields - validate that they exist and have valid values
    if (!fields.containsKey('title') || 
        fields['title'] == null || 
        fields['title'].toString().trim().isEmpty) {
      throw Exception('Discount is missing a title');
    }
    
    // Remove the description validation since it's now optional
    // Use fullDescription as description if available
    String? description;
    if (fields.containsKey('description') && fields['description'] != null) {
      description = fields['description'];
    } else if (fields.containsKey('fullDescription') && fields['fullDescription'] != null) {
      description = fields['fullDescription'];
    }
    
    DateTime expiry = DateTime.now().add(const Duration(days: 30)); // Default expiry
    if (fields.containsKey('expiryDate') && fields['expiryDate'] != null) {
      try {
        expiry = DateTime.parse(fields['expiryDate']);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    // Safely extract storeId
    String storeId = '';
    if (fields.containsKey('store') && fields['store'] != null) {
      final storeData = fields['store'];
      if (storeData is Map && storeData.containsKey('sys')) {
        final sys = storeData['sys'];
        if (sys is Map && sys.containsKey('id')) {
          storeId = sys['id'];
        }
      }
    }
    
    if (storeId.isEmpty) {
      throw Exception('Discount must be associated with a store');
    }
    
    // Safely extract categoryId
    String categoryId = '';
    if (fields.containsKey('category') && fields['category'] != null) {
      final categoryData = fields['category'];
      if (categoryData is Map && categoryData.containsKey('sys')) {
        final sys = categoryData['sys'];
        if (sys is Map && sys.containsKey('id')) {
          categoryId = sys['id'];
        }
      }
    }
    
    if (categoryId.isEmpty) {
      throw Exception('Discount must be associated with a category');
    }

    // Safely extract the image URL
    String? imageUrl;
    if (fields.containsKey('image') && fields['image'] != null) {
      final image = fields['image'];
      if (image is Map && image.containsKey('fields')) {
        final imageFields = image['fields'];
        if (imageFields is Map && imageFields.containsKey('file')) {
          final file = imageFields['file'];
          if (file is Map && file.containsKey('url')) {
            imageUrl = file['url'];
            // Prepend https: if the URL starts with //
            if (imageUrl != null && imageUrl.startsWith('//')) {
              imageUrl = 'https:$imageUrl';
            }
          }
        }
      }
    }

    // Extract fullDescription
    String? fullDescription;
    if (fields.containsKey('fullDescription')) {
      fullDescription = fields['fullDescription'];
    }
    
    // Carefully extract the featured flag
    bool isFeatured = false;
    if (fields.containsKey('featured')) {
      final featuredValue = fields['featured'];
      print('Featured value raw: $featuredValue (${featuredValue.runtimeType})');
      
      if (featuredValue is bool) {
        isFeatured = featuredValue;
      } else if (featuredValue is String) {
        isFeatured = featuredValue.toLowerCase() == 'true';
      } else if (featuredValue is num) {
        isFeatured = featuredValue != 0;
      } else if (featuredValue is Map) {
        // Handle cases where featured might be a reference
        isFeatured = true; // If it exists as a reference, consider it true
      }
    }
    
    print('Final featured flag value: $isFeatured');
    
    // Extract active status
    bool isActive = true;
    if (fields.containsKey('active')) {
      final activeValue = fields['active'];
      if (activeValue is bool) {
        isActive = activeValue;
      } else if (activeValue is String) {
        isActive = activeValue.toLowerCase() == 'true';
      } else if (activeValue is num) {
        isActive = activeValue != 0;
      }
    }
    
    // Extract discount percentage
    double discountPercentage = 0.0;
    if (fields.containsKey('discountPercentage') && fields['discountPercentage'] != null) {
      if (fields['discountPercentage'] is int) {
        discountPercentage = fields['discountPercentage'].toDouble();
      } else if (fields['discountPercentage'] is double) {
        discountPercentage = fields['discountPercentage'];
      } else if (fields['discountPercentage'] is String) {
        try {
          discountPercentage = double.parse(fields['discountPercentage']);
        } catch (e) {
          print('Error parsing discount percentage: $e');
        }
      }
    }
    
    print('Parsed discount ${fields['title']}: featured=$isFeatured, active=$isActive, storeId=$storeId, categoryId=$categoryId');

    return Discount(
      id: entry['sys']['id'],
      title: fields['title'],
      description: description,
      discountPercentage: discountPercentage,
      code: fields['code'],
      storeId: storeId,
      categoryId: categoryId,
      expiryDate: expiry,
      imageUrl: imageUrl,
      featured: isFeatured,
      active: isActive,
      fullDescription: fullDescription,
      storeLogoUrl: fields['storeLogoUrl'],
    );
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
} 