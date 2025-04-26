import 'dart:math' show asin, cos, pi, pow, sin, sqrt;
import 'package:flutter/painting.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationHelper {
  // Calculate distance between two points using Haversine formula
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // in kilometers
    
    final double lat1 = point1.latitude * (pi / 180);
    final double lon1 = point1.longitude * (pi / 180);
    final double lat2 = point2.latitude * (pi / 180);
    final double lon2 = point2.longitude * (pi / 180);
    
    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;
    
    final double a = pow(sin(dLat / 2), 2) + 
                     cos(lat1) * cos(lat2) * 
                     pow(sin(dLon / 2), 2);
                     
    final double c = 2 * asin(sqrt(a));
    final double distance = earthRadius * c; // Distance in km
    
    return double.parse(distance.toStringAsFixed(2));
  }
  
  // Format distance for display
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      // Convert to meters if less than 1 km
      final int meters = (distanceInKm * 1000).round();
      return '$meters m';
    } else {
      return '$distanceInKm km';
    }
  }
  
  // Check location permissions
  static Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    
    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }
  
  // Get current user position
  static Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkLocationPermission();
    
    if (!hasPermission) {
      return null;
    }
    
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }
  
  // Generate custom marker BitmapDescriptor from asset
  static Future<BitmapDescriptor> getMarkerIcon(String iconPath, {double size = 120}) async {
    return BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(size, size)),
      iconPath,
    );
  }
} 