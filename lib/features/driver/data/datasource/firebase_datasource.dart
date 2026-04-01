import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constant.dart';
import '../model/driver_location_model.dart';
import 'package:firebase_core/firebase_core.dart';
class FirebaseDataSource {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://driver-app-3d44c-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );

  late final DatabaseReference _ref =
      _database.ref(AppConstants.firebaseDriverPath);

  Future<void> sendLocation(DriverLocationModel model) async {
  debugPrint('Sending location to Firebase: ${model.toJson()}');
    await _ref.set(model.toJson());
  }

  Future<void> updateTrackingStatus(bool isTracking) async {
    await _ref.update({
      'isTracking': isTracking,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}