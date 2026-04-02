import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/driver_location.dart';

class LocationDataSource {
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() async {
    return Geolocator.requestPermission();
  }

  Future<DriverLocation> getCurrentLocation() async {
    debugPrint('Fetching current location...');
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    debugPrint('Current location fetched: ${position.latitude}, ${position.longitude}');
   

    return DriverLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      isTracking: false,
    );
  }
}