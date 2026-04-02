import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constant.dart';
import '../model/driver_location_model.dart';
class FirebaseDataSource {
  final FirebaseDatabase database;

FirebaseDataSource({required this.database});
  late final DatabaseReference _ref =
      database.ref(AppConstants.firebaseDriverPath);

  Future<void> sendLocation(DriverLocationModel model) async {
  debugPrint('Sending location to Firebase: ${model.toJson()}');
    await _ref.set(model.toJson());
  }

  Future<void> updateTrackingStatus(bool isTracking) async {
    debugPrint('Updating tracking status to Firebase: isTracking=$isTracking');
    await _ref.update({
      'isTracking': isTracking,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}