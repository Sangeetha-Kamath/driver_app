import '../repositories/driver_tracking_repository.dart';

class StopTracking {
  final DriverTrackingRepository repository;

  StopTracking(this.repository);

  Future<void> call() {
    return repository.stopTracking();
  }
}