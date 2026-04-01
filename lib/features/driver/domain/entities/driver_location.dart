class DriverLocation {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool isTracking;

  DriverLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.isTracking,
  });
}