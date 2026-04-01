import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../core/constants/app_constant.dart';
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
    //print the place name based on the coordinates

    // placemarkFromCoordinates(position.latitude, position.longitude).then((placemarks) {
    //   final place = placemarks.first;
    //   debugPrint('Current location: ${place.name}, ${place.locality}, ${place.country}');
    // }).catchError((e) {
    //   debugPrint('Error fetching place name: $e');
    // });


    placemarkFromCoordinates(AppConstants.destinationLat, AppConstants.destinationLng).then((placemarks) {
      final place = placemarks.first;
      debugPrint('Current location: ${place.name}, ${place.locality}, ${place.country}');
    }).catchError((e) {
      debugPrint('Error fetching place name: $e');
    });

    return DriverLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      isTracking: false,
    );
  }
}