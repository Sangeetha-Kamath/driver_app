import '../entities/driver_location.dart';
import '../repositories/driver_tracking_repository.dart';

class GetCurrentLocation {
  final DriverTrackingRepository repository;

  GetCurrentLocation(this.repository);

  Future<DriverLocation> call() {
    return repository.getCurrentLocation();
  }
}