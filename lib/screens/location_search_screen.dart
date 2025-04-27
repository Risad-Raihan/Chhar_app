import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps_flutter;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/store.dart';
import '../providers/category_provider.dart';
import '../services/contentful_service.dart';
import '../utils/app_colors.dart';
import 'store_detail_screen.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({Key? key}) : super(key: key);

  @override
  _LocationSearchScreenState createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> with TickerProviderStateMixin {
  final Completer<google_maps_flutter.GoogleMapController> _controller = Completer();
  final ContentfulService _contentfulService = ContentfulService();
  
  // Default map position (Dhaka)
  static const google_maps_flutter.CameraPosition _dhakaPosition = google_maps_flutter.CameraPosition(
    target: google_maps_flutter.LatLng(23.8103, 90.4125),
    zoom: 12,
  );
  
  google_maps_flutter.LatLng? _currentPosition;
  final TextEditingController _searchController = TextEditingController();
  
  List<Store> _allStores = [];
  List<Store> _nearbyStores = [];
  Map<String, google_maps_flutter.Marker> _markers = {};
  bool _isLoading = true;
  bool _isSearching = false;
  String? _searchError;
  String _searchAddress = 'Search for a location...';
  
  late AnimationController _mapAnimationController;
  late AnimationController _listAnimationController;
  bool _showMap = true;
  
  @override
  void initState() {
    super.initState();
    _mapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _loadStores();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapAnimationController.dispose();
    _listAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Load all stores from Contentful
  Future<void> _loadStores() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final stores = await _contentfulService.getStores();
      
      // Filter stores with location data
      final storesWithLocation = stores.where((store) => store.hasLocation).toList();
      
      setState(() {
        _allStores = storesWithLocation;
        _isLoading = false;
      });
      
      if (_currentPosition != null) {
        _updateNearbyStores();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _searchError = 'Failed to load stores: $e';
      });
    }
  }
  
  // Request location permission and get current location
  Future<void> _getCurrentLocation() async {
    try {
      if (_isLoading) return;

      setState(() {
        _isLoading = true;
        _searchError = null;
      });

      // Check if location service is enabled
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _searchError = 'Location services are disabled. Please enable location in settings.';
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _searchError = 'Location permissions are denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _searchError = 'Location permissions are permanently denied. Please enable them in settings.';
        });
        return;
      }

      // When permissions are granted
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = google_maps_flutter.LatLng(position.latitude, position.longitude);
      });

      // Get address from coordinates
      await _getAddressFromCoordinates(position);

      // Update map camera position
      final google_maps_flutter.GoogleMapController controller = await _controller.future;
      controller.animateCamera(google_maps_flutter.CameraUpdate.newCameraPosition(
        google_maps_flutter.CameraPosition(
          target: google_maps_flutter.LatLng(position.latitude, position.longitude),
          zoom: 15.0,
        ),
      ));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting current location: $e');
      setState(() {
        _isLoading = false;
        _searchError = 'Could not get current location. Please try again.';
      });
    }
  }
  
  // Get address from coordinates
  Future<void> _getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _searchAddress = '${place.street}, ${place.locality}, ${place.country}';
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }
  
  // Move map camera to specified location
  Future<void> _moveToLocation(google_maps_flutter.LatLng location) async {
    final google_maps_flutter.GoogleMapController controller = await _controller.future;
    controller.animateCamera(google_maps_flutter.CameraUpdate.newCameraPosition(
      google_maps_flutter.CameraPosition(
        target: location,
        zoom: 14,
      ),
    ));
  }
  
  // Search for a location by address
  Future<void> _searchLocation(String address) async {
    if (address.isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        final newLocation = google_maps_flutter.LatLng(location.latitude, location.longitude);
        
        // Reverse geocode to get full address
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        
        String fullAddress = address;
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          fullAddress = '${place.street}, ${place.locality}, ${place.country}';
        }
        
        setState(() {
          _currentPosition = newLocation;
          _searchAddress = fullAddress;
          _isSearching = false;
        });
        
        _moveToLocation(newLocation);
        _updateNearbyStores();
      }
    } catch (e) {
      setState(() {
        _searchError = 'Location not found. Please try again.';
        _isSearching = false;
      });
    }
  }
  
  // Calculate distance between current location and store
  double _calculateDistance(Store store) {
    if (_currentPosition == null || !store.hasLocation) {
      return double.infinity;
    }
    
    // Use the Haversine formula to calculate distance
    double userLat = _currentPosition!.latitude;
    double userLng = _currentPosition!.longitude;
    double storeLat = store.latitude!;
    double storeLng = store.longitude!;
    
    double latDistance = _degreesToRadians(storeLat - userLat);
    double lngDistance = _degreesToRadians(storeLng - userLng);
    
    double a = math.sin(latDistance / 2) * math.sin(latDistance / 2)
        + math.cos(_degreesToRadians(userLat)) * math.cos(_degreesToRadians(storeLat))
        * math.sin(lngDistance / 2) * math.sin(lngDistance / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    // Earth radius in kilometers
    const double radius = 6371;
    double distance = radius * c;
    
    return distance;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
  
  // Update nearby stores based on current location
  void _updateNearbyStores() {
    if (_currentPosition == null || _allStores.isEmpty) return;
    
    // Sort stores by distance (simple calculation for now)
    final sortedStores = List<Store>.from(_allStores);
    if (_currentPosition != null) {
      sortedStores.sort((a, b) {
        final distA = _calculateDistance(a);
        final distB = _calculateDistance(b);
        return distA.compareTo(distB);
      });
    }
    
    // Create markers for each store
    _markers = {};
    
    for (int i = 0; i < sortedStores.length; i++) {
      final store = sortedStores[i];
      if (store.latitude != null && store.longitude != null) {
        final markerId = google_maps_flutter.MarkerId(store.id);
        
        // Create custom marker icon based on store category or logo
        _markers[store.id] = google_maps_flutter.Marker(
          markerId: markerId,
          position: google_maps_flutter.LatLng(store.latitude!, store.longitude!),
          infoWindow: google_maps_flutter.InfoWindow(
            title: store.name,
            snippet: store.displayDescription,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoreDetailScreen(store: store),
                ),
              );
            },
          ),
          onTap: () {
            // Highlight the selected store in the list
          },
        );
      }
    }
    
    setState(() {
      _nearbyStores = sortedStores;
    });
  }
  
  // Toggle between map and list view
  void _toggleView() {
    setState(() {
      _showMap = !_showMap;
      if (_showMap) {
        _mapAnimationController.forward();
        _listAnimationController.reverse();
      } else {
        _mapAnimationController.reverse();
        _listAnimationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int index = 0; // Initialize index variable
    return Scaffold(
      body: _buildAnimatedBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
  
  Widget _buildAnimatedBody() {
    return Stack(
      children: [
        // Map View
        AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          top: 0,
          left: 0,
          right: 0,
          bottom: _showMap ? 0 : MediaQuery.of(context).size.height * 0.6,
          child: _buildGoogleMap(),
        ),
        
        // Top Bar with Search
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: _buildSearchBar().animate().fadeIn(duration: 600.ms),
        ),
        
        // Bottom Sheet with Store List
        AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          left: 0,
          right: 0,
          bottom: 0,
          height: _showMap ? MediaQuery.of(context).size.height * 0.4 : MediaQuery.of(context).size.height * 0.85,
          child: _buildStoresList(),
        ),
        
        // Loading Indicator
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: _buildLoadingIndicator(),
            ),
          ),
      ],
    );
  }
  
  Widget _buildGoogleMap() {
    return google_maps_flutter.GoogleMap(
      mapType: google_maps_flutter.MapType.normal,
      initialCameraPosition: _dhakaPosition,
      markers: Set<google_maps_flutter.Marker>.of(_markers.values),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: true,
      onMapCreated: (google_maps_flutter.GoogleMapController controller) {
        _controller.complete(controller);
      },
    ).animate().fadeIn(duration: 800.ms);
  }
  
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search by Location',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadStores,
                ),
              ],
            ),
          ),
          
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceColor,
                    ),
                    onSubmitted: _searchLocation,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.location_searching, color: Colors.white),
                    onPressed: () {
                      if (_searchController.text.isNotEmpty) {
                        _searchLocation(_searchController.text);
                      } else {
                        _getCurrentLocation();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Current Address
          if (_searchAddress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.primaryLightColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _searchAddress,
                      style: const TextStyle(
                        color: AppColors.textSecondaryColor,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          
          // Error Message
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _searchError!,
                style: const TextStyle(
                  color: AppColors.errorColor,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildStoresList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with count and toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_nearbyStores.length} Nearby Stores',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: Icon(_showMap ? Icons.list : Icons.map),
                  label: Text(_showMap ? 'View List' : 'View Map'),
                  onPressed: _toggleView,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          const Divider(height: 1),
          
          // Store List
          Expanded(
            child: _nearbyStores.isEmpty
                ? Center(
                    child: Text(
                      _isLoading ? 'Loading stores...' : 'No stores found nearby.',
                      style: const TextStyle(color: AppColors.textSecondaryColor),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _nearbyStores.length,
                    itemBuilder: (context, index) {
                      final store = _nearbyStores[index];
                      return _buildStoreCard(store, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStoreCard(Store store, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StoreDetailScreen(store: store)),
        );
      },
      child: Animate(
        effects: [
          FadeEffect(duration: 300.ms, delay: (100 * index).ms),
          SlideEffect(begin: const Offset(0.2, 0), end: Offset.zero, duration: 400.ms, delay: (100 * index).ms),
        ],
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Store image or placeholder
                    Container(
                      height: 120,
                      width: double.infinity,
                      color: AppColors.surfaceColor,
                      child: store.logoUrl != null && store.logoUrl!.isNotEmpty
                          ? Image.network(
                              store.logoUrl!.startsWith('http')
                                  ? store.logoUrl!
                                  : 'https:${store.logoUrl!}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading store image in location search: $error for URL: ${store.logoUrl}');
                                return const Center(
                                  child: Icon(Icons.store, size: 40, color: Colors.grey),
                                );
                              },
                            )
                          : const Center(
                              child: Icon(Icons.store, size: 40, color: Colors.grey),
                            ),
                    ),
                    
                    // Location animation on top-right corner
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Lottie.asset(
                          'assets/animations/location-pin.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    
                    // Distance badge
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.directions,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_calculateDistance(store).toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentTeal.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Consumer<CategoryProvider>(
                            builder: (context, categoryProvider, _) {
                              // Use the synchronous method to avoid state changes during build
                              final categoryNames = categoryProvider.getCategoryNamesSync(store.categoryIds);
                              final displayName = categoryNames.isNotEmpty 
                                  ? categoryNames.first
                                  : 'General';
                              
                              return Text(
                                displayName,
                                style: const TextStyle(
                                  color: AppColors.accentTeal,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      store.displayDescription,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _getCurrentLocation,
      child: const Icon(Icons.my_location),
    ).animate().scale(delay: 300.ms);
  }
  
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryColor),
          const SizedBox(height: 16),
          const Text('Loading Map...'),
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: AppColors.textSecondaryColor.withOpacity(0.3),
            highlightColor: AppColors.textSecondaryColor.withOpacity(0.6),
            child: Container(
              width: 160,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 