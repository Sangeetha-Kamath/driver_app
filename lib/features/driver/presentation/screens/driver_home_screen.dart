import 'package:driver_app/features/driver/presentation/screens/live_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constant.dart';
import '../controller/driver_tracking_controller.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  Widget infoCard({
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: (iconColor ?? Colors.green).withOpacity(0.12),
          child: Icon(icon, color: iconColor ?? Colors.green),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DriverTrackingController>();
    final location = controller.currentLocation;

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Dashboard')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1FAA59), Color(0xFF159947)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.delivery_dining,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Food Delivery Agent',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.statusText,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          controller.isTracking
                              ? Icons.location_on
                              : Icons.location_disabled,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          controller.isTracking
                              ? 'Tracking is LIVE'
                              : 'Tracking is OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              sectionTitle(context, 'Delivery Status'),
              infoCard(
                title: 'Permission Status',
                value: controller.isPermissionGranted
                    ? 'Granted'
                    : 'Not Granted',
                icon: Icons.lock_open_rounded,
                iconColor: Colors.blue,
              ),
              infoCard(
                title: 'Tracking Status',
                value: controller.isTracking ? 'ON' : 'OFF',
                icon: Icons.location_searching_rounded,
                iconColor: controller.isTracking
                    ? Colors.green
                    : Colors.redAccent,
              ),
              const SizedBox(height: 12),
              sectionTitle(context, 'Current Location'),
              infoCard(
                title: 'Latitude',
                value: location == null
                    ? '--'
                    : location.latitude.toStringAsFixed(6),
                icon: Icons.my_location_rounded,
                iconColor: Colors.deepPurple,
              ),
              infoCard(
                title: 'Longitude',
                value: location == null
                    ? '--'
                    : location.longitude.toStringAsFixed(6),
                icon: Icons.explore_rounded,
                iconColor: Colors.orange,
              ),
              const SizedBox(height: 12),
              sectionTitle(context, 'Delivery Destination'),
              infoCard(
                title: 'Destination',
                value: controller.destinationName,
                icon: Icons.place_rounded,
                iconColor: Colors.redAccent,
              ),
              const SizedBox(height: 24),
             
             
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: controller.requestLocationPermission,
                icon: const Icon(Icons.gpp_good_rounded),
                label: const Text('Grant Location Permission'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  debugPrint(
                    'Fetch Current Location button pressed:${controller.isLoadingLocation}',
                  );
                  controller.isLoadingLocation
                      ? null
                      : controller.fetchCurrentLocation();
                },
                icon: const Icon(Icons.my_location_rounded),
                label: Text(
                  controller.isLoadingLocation
                      ? 'Fetching Current Location...'
                      : 'Set Current Location',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  controller.isTracking
                    ? null
                    : await controller.startTracking();
if (context.mounted && controller.isTracking) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
  );
}
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1FAA59),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Tracking'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: controller.isTracking
                    ? controller.stopTracking
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop Tracking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


