import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../../domain/entities/driver_location.dart';
import '../../domain/repositories/driver_tracking_repository.dart';
import '../datasource/firebase_datasource.dart';
import '../datasource/location_datasource.dart';
import '../model/driver_location_model.dart';


class DriverTrackingRepositoryImpl implements DriverTrackingRepository {
  final LocationDataSource locationDataSource;
  final FirebaseDataSource firebaseDataSource;
  final FlutterBackgroundService service;

  DriverTrackingRepositoryImpl({
    required this.locationDataSource,
    required this.firebaseDataSource,
    required this.service,
  });

  @override
  Future<DriverLocation> getCurrentLocation() async {
    final location = await locationDataSource.getCurrentLocation();
    
    await sendLocation(location);
    return location;
  }

  @override
  Future<void> sendLocation(DriverLocation location) async {
    final model = DriverLocationModel.fromEntity(location);
    await firebaseDataSource.sendLocation(model);
  }

  @override
  Future<void> startTracking() async {
    final isRunning = await service.isRunning();

    if (!isRunning) {
      await service.startService();
      await Future.delayed(const Duration(seconds: 1));
    }

    service.invoke('startTracking');
  }

  @override
  Future<void> stopTracking() async {
    service.invoke('stopTracking');
    await firebaseDataSource.updateTrackingStatus(false);
  }
}