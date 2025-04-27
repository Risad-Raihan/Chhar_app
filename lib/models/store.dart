class Store {
  final String id;
  final String name;
  final String? description;
  final String? _logoUrl;
  final String? website;
  final List<String> categoryIds;
  final bool featured;
  final double? latitude;
  final double? longitude;
  final String? address;

  // Add getter for logo (backward compatibility)
  String? get logo => logoUrl;
  
  // Add a getter for displayDescription
  String get displayDescription => description ?? '';
  
  // Add a better getter for logoUrl that handles URL formatting and ensures URL validity
  String? get logoUrl {
    if (_logoUrl == null || _logoUrl!.isEmpty) return null;
    
    // Handle various URL formats
    String formattedUrl;
    if (_logoUrl!.startsWith('//')) {
      formattedUrl = 'https:$_logoUrl';
    } else if (_logoUrl!.startsWith('http://') || _logoUrl!.startsWith('https://')) {
      formattedUrl = _logoUrl!;
    } else {
      formattedUrl = 'https://$_logoUrl';
    }
    
    return formattedUrl;
  }

  Store({
    required this.id,
    required this.name,
    this.description,
    String? logoUrl,
    this.website,
    required this.categoryIds,
    required this.featured,
    this.latitude,
    this.longitude,
    this.address,
  }) : _logoUrl = logoUrl;

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
    print('Extracting logo for store: ${fields['name']}');
    
    if (fields.containsKey('logo')) {
      print('Logo field exists. Raw logo data: ${fields['logo']}');
      final logo = fields['logo'];
      
      // Handle direct URL string case
      if (logo is String) {
        print('Logo is a direct string: $logo');
        logoUrl = logo;
      } 
      // Handle reference case
      else if (logo is Map) {
        print('Logo is a reference object with structure: $logo');
        
        // Try to extract from sys.id reference
        if (logo.containsKey('sys') && logo['sys'] is Map) {
          final sys = logo['sys'] as Map;
          print('Logo sys structure: $sys');
          
          // Try to find the asset in includes section
          if (sys.containsKey('id') && sys['id'] is String) {
            final assetId = sys['id'];
            print('Logo asset ID: $assetId');
            
            // Look for includes in the main entry
            if (entry.containsKey('includes')) {
              final includes = entry['includes'];
              print('Found includes in entry: ${includes.keys.join(", ")}');
              
              if (includes is Map && includes.containsKey('Asset') && includes['Asset'] is List) {
                final assets = includes['Asset'] as List;
                print('Found ${assets.length} assets in includes');
                
                try {
                  // Try to find the asset with matching ID
                  final asset = assets.firstWhere(
                    (asset) => asset['sys'] != null && 
                              asset['sys'] is Map && 
                              asset['sys']['id'] == assetId,
                    orElse: () => <String, dynamic>{},
                  );
                  
                  if (asset.isNotEmpty) {
                    print('Found matching asset: ${asset['sys']['id']}');
                    
                    if (asset.containsKey('fields') &&
                        asset['fields'] is Map &&
                        asset['fields'].containsKey('file') &&
                        asset['fields']['file'] is Map &&
                        asset['fields']['file'].containsKey('url')) {
                      logoUrl = asset['fields']['file']['url'];
                      print('Found logo URL in includes: $logoUrl');
                    } else {
                      print('Asset structure not as expected: ${asset['fields']}');
                    }
                  } else {
                    print('Could not find asset with ID $assetId in includes');
                  }
                } catch (e) {
                  print('Error finding asset with ID $assetId: $e');
                }
              } else {
                print('No Asset list found in includes or wrong structure');
                if (includes is Map) {
                  print('Includes keys: ${includes.keys.join(", ")}');
                } else {
                  print('Includes is not a map');
                }
              }
            } else {
              print('No includes in entry');
            }
          } else {
            print('No ID in sys object');
          }
        }
      }
    } else {
      print('No logo field found for ${fields['name']}');
    }
    
    // Validate and clean up URL format
    if (logoUrl != null) {
      print('Pre-formatted logo URL: $logoUrl');
      if (logoUrl.startsWith('//')) {
        logoUrl = 'https:$logoUrl';
      } else if (!logoUrl.startsWith('http://') && !logoUrl.startsWith('https://')) {
        logoUrl = 'https://$logoUrl';
      }
      print('Final formatted logo URL: $logoUrl');
    } else {
      print('No logo URL found after extraction attempts');
    }
    
    // Parse location data
    double? latitude;
    double? longitude;
    if (fields.containsKey('location') && fields['location'] != null) {
      try {
        final locationData = fields['location'];
        print('Parsing location data: $locationData (type: ${locationData.runtimeType})');
        
        if (locationData is Map) {
          // Handle different possible formats for location data
          
          // Format 1: {lat: value, lon: value}
          if (locationData.containsKey('lat') && locationData.containsKey('lon')) {
            latitude = double.tryParse(locationData['lat'].toString());
            longitude = double.tryParse(locationData['lon'].toString());
            print('Format 1 location data - lat: $latitude, lon: $longitude');
          }
          // Format 2: Contentful location format with latitude and longitude fields
          else if (locationData.containsKey('latitude') && locationData.containsKey('longitude')) {
            latitude = double.tryParse(locationData['latitude'].toString());
            longitude = double.tryParse(locationData['longitude'].toString());
            print('Format 2 location data - latitude: $latitude, longitude: $longitude');
          }
          // Format 3: Raw coordinates in specific format {"lat": value, "lon": value}
          else if (locationData.toString().contains("lat") && locationData.toString().contains("lon")) {
            final locationString = locationData.toString();
            final latPattern = RegExp(r'"lat"\s*:\s*([0-9.-]+)');
            final lonPattern = RegExp(r'"lon"\s*:\s*([0-9.-]+)');
            
            final latMatch = latPattern.firstMatch(locationString);
            final lonMatch = lonPattern.firstMatch(locationString);
            
            if (latMatch != null && lonMatch != null) {
              latitude = double.tryParse(latMatch.group(1) ?? '');
              longitude = double.tryParse(lonMatch.group(1) ?? '');
              print('Format 3 location data - latMatch: ${latMatch.group(1)}, lonMatch: ${lonMatch.group(1)}');
            }
          }
        } else if (locationData is String) {
          // Format 4: Comma-separated string like "23.8103, 90.4125"
          final parts = locationData.split(',');
          if (parts.length == 2) {
            latitude = double.tryParse(parts[0].trim());
            longitude = double.tryParse(parts[1].trim());
            print('Format 4 location data - lat: $latitude, lon: $longitude');
          }
        }
      } catch (e) {
        print('Error parsing location data: $e');
      }
    } else {
      // Check for separate latitude and longitude fields
      if (fields.containsKey('latitude') && fields.containsKey('longitude')) {
        latitude = double.tryParse(fields['latitude'].toString());
        longitude = double.tryParse(fields['longitude'].toString());
        print('Separate latitude/longitude fields - lat: $latitude, lon: $longitude');
      }
    }
    
    // Finally print if location was successfully parsed
    if (latitude != null && longitude != null) {
      print('Successfully parsed location: $latitude, $longitude');
    } else {
      print('Failed to parse location from data');
    }

    print('  - Store ID: ${entry['sys']['id']}, Name: ${fields['name']}, hasLocation: ${latitude != null && longitude != null}, hasLogo: ${logoUrl != null}');
    if (latitude != null && longitude != null) {
      print('  - Coordinates: $latitude, $longitude');
    }
    
    if (logoUrl != null) {
      print('  - Logo URL: $logoUrl');
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