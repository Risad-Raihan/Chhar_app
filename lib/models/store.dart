
class Store {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final String? website;
  final List<String> categoryIds;
  final bool featured;
  final double? latitude;
  final double? longitude;
  final String? address;

  // Add getter for logo (backward compatibility)
  String? get logo => logoUrl;

  Store({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    this.website,
    required this.categoryIds,
    required this.featured,
    this.latitude,
    this.longitude,
    this.address,
  });

  factory Store.fromContentful(Map<String, dynamic> entry) {
    final fields = entry['fields'] as Map<String, dynamic>;
    
    // Extract category IDs
    List<String> extractedCategoryIds = [];
    if (fields.containsKey('categories') && fields['categories'] is List) {
      try {
        extractedCategoryIds = (fields['categories'] as List)
            .where((category) => category is Map && category.containsKey('sys'))
            .map((category) {
              final sys = category['sys'];
              if (sys is Map && sys.containsKey('id')) {
                return sys['id'] as String;
              }
              return '';
            })
            .where((id) => id.isNotEmpty)
            .toList();
      } catch (e) {
        print('Error extracting category IDs: $e');
      }
    }

    // Safely extract the logo URL
    String? logoUrl;
    if (fields.containsKey('logo') && fields['logo'] != null) {
      final logo = fields['logo'];
      if (logo is Map && logo.containsKey('fields')) {
        final logoFields = logo['fields'];
        if (logoFields is Map && logoFields.containsKey('file')) {
          final file = logoFields['file'];
          if (file is Map && file.containsKey('url')) {
            logoUrl = file['url'];
            // Prepend https: if the URL starts with //
            if (logoUrl != null && logoUrl.startsWith('//')) {
              logoUrl = 'https:$logoUrl';
            }
          }
        }
      }
    }
    
    // Parse location data
    double? latitude;
    double? longitude;
    if (fields.containsKey('location') && fields['location'] != null) {
      try {
        final locationData = fields['location'];
        if (locationData is Map) {
          if (locationData.containsKey('lat')) {
            latitude = double.tryParse(locationData['lat'].toString());
          }
          if (locationData.containsKey('lon')) {
            longitude = double.tryParse(locationData['lon'].toString());
          }
        }
      } catch (e) {
        print('Error parsing location data: $e');
      }
    }

    return Store(
      id: entry['sys']['id'],
      name: fields['name'] ?? '',
      description: fields['description'] ?? '',
      logoUrl: logoUrl,
      website: fields['website'] ?? '',
      categoryIds: extractedCategoryIds,
      featured: fields['featured'] ?? false,
      latitude: latitude,
      longitude: longitude,
      address: fields['address'] as String?,
    );
  }
  
  // Check if the store has valid location data
  bool get hasLocation => latitude != null && longitude != null;
  
  // Calculate distance from user (will be implemented)
  double distanceFrom(double userLat, double userLng) {
    // We'll implement this later using geolocator
    return 0.0;
  }
} 