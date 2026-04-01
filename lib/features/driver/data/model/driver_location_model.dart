import '../../domain/entities/driver_location.dart';

class DriverLocationModel extends DriverLocation {
  DriverLocationModel({
    required super.latitude,
    required super.longitude,
    required super.timestamp,
    required super.isTracking,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lng': longitude,
      'timestamp': timestamp.toIso8601String(),
      'isTracking': isTracking,
    };
  }

  factory DriverLocationModel.fromEntity(DriverLocation entity) {
    return DriverLocationModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      timestamp: entity.timestamp,
      isTracking: entity.isTracking,
    );
  }
}