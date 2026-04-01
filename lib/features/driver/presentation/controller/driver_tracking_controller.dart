import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_constant.dart';
import '../../domain/entities/driver_location.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/start_tracking.dart';
import '../../domain/usecases/stop_tracking.dart';
import '../screens/live_tracking_screen.dart';

class DriverTrackingController extends ChangeNotifier {
  final GetCurrentLocation getCurrentLocationUseCase;
  final StartTracking startTrackingUseCase;
  final StopTracking stopTrackingUseCase;

  DriverTrackingController({
    required this.getCurrentLocationUseCase,
    required this.startTrackingUseCase,
    required this.stopTrackingUseCase,
  });

  DriverLocation? currentLocation;
  bool isPermissionGranted = false;
  bool isTracking = false;
  bool isLoadingLocation = false;
  String statusText = 'Idle';

  StreamSubscription<Position>? _positionSubscription;

  String get destinationName => AppConstants.destinationName;

  Future<void> init() async {
    final permission = await Geolocator.checkPermission();
    isPermissionGranted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    notifyListeners();
  }

  Future<void> requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      statusText = 'Please enable location service';
      notifyListeners();
      return;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      statusText = 'Permission denied forever';
      notifyListeners();
      return;
    }

    isPermissionGranted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    notifyListeners();
  }

  Future<void> fetchCurrentLocation() async {
    debugPrint('Fetching current location...');
    isLoadingLocation = true;
    notifyListeners();

    try {
      await requestLocationPermission();

      if (!isPermissionGranted) {
        statusText = 'Grant location permission first';
        notifyListeners();
        return;
      }

      currentLocation = await getCurrentLocationUseCase.call();
      statusText = 'Current location fetched';
    } catch (e) {
      debugPrint('fetchCurrentLocation error: $e');
      statusText = 'Failed to get current location';
    } finally {
      isLoadingLocation = false;
      notifyListeners();
    }
  }

  Future<void> startTracking() async {
    await requestLocationPermission();

    if (!isPermissionGranted) {
      statusText = 'Grant location permission first';
      notifyListeners();
      return;
    }

    if (currentLocation == null) {
      await fetchCurrentLocation();
    }
    if (currentLocation == null) {
      statusText = 'Unable to fetch current location';
      notifyListeners();
      return;
    }

    try {
      // Start Firebase/background service updates
      await startTrackingUseCase.call();

      // Start UI updates in foreground so both HomeScreen and LiveTrackingScreen
      // can listen only to this controller.
      await _positionSubscription?.cancel();

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      );

      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (position) {
              currentLocation = DriverLocation(
                latitude: position.latitude,
                longitude: position.longitude,
                timestamp: DateTime.now(),
                isTracking: true,
              );

              notifyListeners();
            },
            onError: (error) {
              debugPrint('Foreground tracking stream error: $error');
            },
          );

      isTracking = true;
      statusText = 'Tracking started';
      notifyListeners();
    } catch (e) {
      debugPrint('startTracking error: $e');
      statusText = 'Failed to start tracking';
      notifyListeners();
    } finally {}
  }

  Future<void> stopTracking() async {
    try {
      await stopTrackingUseCase.call();
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      isTracking = false;

      if (currentLocation != null) {
        currentLocation = DriverLocation(
          latitude: currentLocation!.latitude,
          longitude: currentLocation!.longitude,
          timestamp: DateTime.now(),
          isTracking: false,
        );
      }

      statusText = 'Tracking stopped';
      notifyListeners();
    } catch (e) {
      debugPrint('stopTracking error: $e');
      statusText = 'Failed to stop tracking';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
