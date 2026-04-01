import '../entities/driver_location.dart';

abstract class DriverTrackingRepository {
  Future<DriverLocation> getCurrentLocation();
  Future<void> sendLocation(DriverLocation location);
  Future<void> startTracking();
  Future<void> stopTracking();
}