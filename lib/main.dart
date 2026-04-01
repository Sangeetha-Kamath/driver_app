import 'dart:async';

import 'package:driver_app/core/theme/app_theme.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constant.dart';
import 'features/driver/data/datasource/firebase_datasource.dart';
import 'features/driver/data/datasource/location_datasource.dart';
import 'features/driver/data/repositories/driver_tracking_repository_impl.dart';
import 'features/driver/domain/usecases/get_current_location.dart';
import 'features/driver/domain/usecases/start_tracking.dart';
import 'features/driver/domain/usecases/stop_tracking.dart';
import 'features/driver/presentation/controller/driver_tracking_controller.dart';
import 'features/driver/presentation/screens/driver_home_screen.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
 
 
  await configureBackgroundService();

  final service = FlutterBackgroundService();

  final repository = DriverTrackingRepositoryImpl(
    locationDataSource: LocationDataSource(),
    firebaseDataSource: FirebaseDataSource(),
    service: service,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => DriverTrackingController(
        getCurrentLocationUseCase: GetCurrentLocation(repository),
        startTrackingUseCase: StartTracking(repository),
        stopTrackingUseCase: StopTracking(repository),
      )..init(),
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
       themeMode: ThemeMode.system,
      home: const DriverHomeScreen(),
    );
  }
}

Future<void> configureBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      foregroundServiceNotificationId: 1001,
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

  final dbRef = FirebaseDatabase.instance.ref(AppConstants.firebaseDriverPath);
  StreamSubscription<Position>? positionSubscription;

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Delivery Tracking Active',
      content: 'Preparing location updates...',
    );
  }

  service.on('startTracking').listen((event) async {
    await positionSubscription?.cancel();

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5
    );

    positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) async {
      await dbRef.set({
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'isTracking': true,
      });

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Delivery Tracking Active',
          content:
              'Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}',
        );
      }
    });
  });

  service.on('stopTracking').listen((event) async {
    await positionSubscription?.cancel();
    positionSubscription = null;

    await dbRef.update({
      'isTracking': false,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Delivery Tracking Stopped',
        content: 'Location updates stopped',
      );
    }
  });
}