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
  final firebaseDatabase = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        AppConstants.databaseUrl,
  );
  final FirebaseDataSource firebaseDataSource = FirebaseDataSource(database: firebaseDatabase);

  final repository = DriverTrackingRepositoryImpl(
    locationDataSource: LocationDataSource(),
    firebaseDataSource: firebaseDataSource,
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
  debugPrint('Firebase initialized inside background isolate');

  final firebaseDatabase = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: AppConstants.databaseUrl,
  );
  debugPrint('onStart() CALLED in background isolate');

  final dbRef = firebaseDatabase.ref(AppConstants.firebaseDriverPath);

  StreamSubscription<Position>? positionSubscription;

  service.on('startTracking').listen((event) async {
    await positionSubscription?.cancel();

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {   
      debugPrint('Permission denied');
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      //distanceFilter: 5,
    );

    positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) async {
      try {
        debugPrint('Before Firebase update: ${position.latitude}, ${position.longitude}');

        await dbRef.update({
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
          'isTracking': true,
        }).timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw Exception('Firebase update timed out'),
        );

        debugPrint('After Firebase update');

        final snapshot = await dbRef.get();
        debugPrint('Firebase value after write: ${snapshot.value}');
      } catch (e, st) {
        debugPrint('Firebase write error: $e');
        debugPrint('$st');
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