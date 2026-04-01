import '../repositories/driver_tracking_repository.dart';

class StartTracking {
  final DriverTrackingRepository repository;

  StartTracking(this.repository);

  Future<void> call() {
    return repository.startTracking();
  }
}