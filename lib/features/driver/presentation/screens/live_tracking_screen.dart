import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constant.dart';
import '../controller/driver_tracking_controller.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  late final PolylinePoints _polylinePoints;

  static const LatLng _destination = LatLng(AppConstants.destinationLat, AppConstants.destinationLng);

  final Set<Marker> _markers = <Marker>{};
  final Set<Polyline> _polylines = <Polyline>{};

  bool _hasShownReachedDialog = false;
  bool _isLoadingRoute = false;
  String? _routeDebugMessage;

  LatLng? _lastPolylineOrigin;
  LatLng? _lastCameraTarget;

  LatLng? _lastMarkerUpdatePosition;
  DateTime? _lastMarkerUpdateTime;

  LatLng? _lastPolylineUpdatePosition;
  DateTime? _lastPolylineUpdateTime;

  LatLng? _lastCameraUpdatePosition;
  DateTime? _lastCameraUpdateTime;



static const double _markerUpdateDistanceThreshold = 10;
static const double _polylineUpdateDistanceThreshold = 25;
static const double _cameraUpdateDistanceThreshold = 10;

 

  DriverTrackingController? _trackingController;

  @override
  void initState() {
    super.initState();
    _polylinePoints = PolylinePoints(apiKey: AppConstants.api_key);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _trackingController = context.read<DriverTrackingController>();
      _trackingController?.addListener(_onTrackingUpdated);

      final location = _trackingController?.currentLocation;
      if (location == null) {
        _setDebugMessage('Current location is unavailable');
        return;
      }

      final currentLatLng = LatLng(location.latitude, location.longitude);
      _updateMapData(currentLatLng, moveCamera: true);
    });
  }

  void _onTrackingUpdated() {
    if (!mounted) return;

    final location = _trackingController?.currentLocation;
    if (location == null) return;

    final currentLatLng = LatLng(location.latitude, location.longitude);
    _updateMapData(currentLatLng);
  }

  @override
  void dispose() {
    _trackingController?.removeListener(_onTrackingUpdated);
    super.dispose();
  }

  void _setDebugMessage(String message) {
    debugPrint(message);
    if (!mounted) return;
    setState(() {
      _routeDebugMessage = message;
    });
  }

  bool _shouldUpdateMarker(LatLng currentLatLng) {
    

    if (_lastMarkerUpdatePosition == null || _lastMarkerUpdateTime == null) {
      return true;
    }

    final distance = _calculateDistanceInMeters(
      _lastMarkerUpdatePosition!.latitude,
      _lastMarkerUpdatePosition!.longitude,
      currentLatLng.latitude,
      currentLatLng.longitude,
    );

    

    return distance >= _markerUpdateDistanceThreshold ;
  }

  bool _shouldUpdatePolyline(LatLng currentLatLng) {
   

    if (_lastPolylineUpdatePosition == null || _lastPolylineUpdateTime == null) {
      return true;
    }

    final distance = _calculateDistanceInMeters(
      _lastPolylineUpdatePosition!.latitude,
      _lastPolylineUpdatePosition!.longitude,
      currentLatLng.latitude,
      currentLatLng.longitude,
    );

    

    return distance >= _polylineUpdateDistanceThreshold;
     
  }

  bool _shouldMoveCamera(LatLng currentLatLng) {
   

    if (_lastCameraUpdatePosition == null || _lastCameraUpdateTime == null) {
      return true;
    }

    final distance = _calculateDistanceInMeters(
      _lastCameraUpdatePosition!.latitude,
      _lastCameraUpdatePosition!.longitude,
      currentLatLng.latitude,
      currentLatLng.longitude,
    );

    

    return distance >= _cameraUpdateDistanceThreshold;
        
  }

  Future<void> _updateMapData(
    LatLng currentLatLng, {
    bool moveCamera = false,
  }) async {
    if (_shouldUpdateMarker(currentLatLng)) {
      _updateMarkers(currentLatLng);
      _lastMarkerUpdatePosition = currentLatLng;
      _lastMarkerUpdateTime = DateTime.now();
    }

    if (_shouldUpdatePolyline(currentLatLng)) {
      await _updatePolyline(currentLatLng);
      _lastPolylineUpdatePosition = currentLatLng;
      _lastPolylineUpdateTime = DateTime.now();
    }

    if (moveCamera || _shouldMoveCamera(currentLatLng)) {
      await _moveCamera(currentLatLng);
      _lastCameraTarget = currentLatLng;
      _lastCameraUpdatePosition = currentLatLng;
      _lastCameraUpdateTime = DateTime.now();
    }

    _checkIfReached(currentLatLng);
  }

  void _updateMarkers(LatLng currentLatLng) {
    debugPrint(
      'Current location fetched: ${currentLatLng.latitude}, ${currentLatLng.longitude}',
    );
    debugPrint(
      'Current location fetched destination: ${_destination.latitude}, ${_destination.longitude}',
    );

    final sourceMarker = Marker(
      markerId: const MarkerId('source'),
      position: currentLatLng,
      infoWindow: const InfoWindow(title: 'Current Location'),
    );

    const destinationMarker = Marker(
      markerId: MarkerId('destination'),
      position: _destination,
      infoWindow: InfoWindow(title: 'Destination'),
    );

    if (!mounted) return;
    setState(() {
      _markers
        ..clear()
        ..add(sourceMarker)
        ..add(destinationMarker);
    });
  }

  Future<void> _updatePolyline(LatLng currentLatLng) async {
    if (_isLoadingRoute) return;

    if (_lastPolylineOrigin != null) {
      final distanceFromLastRouteOrigin = _calculateDistanceInMeters(
        _lastPolylineOrigin!.latitude,
        _lastPolylineOrigin!.longitude,
        currentLatLng.latitude,
        currentLatLng.longitude,
      );

      if (distanceFromLastRouteOrigin < 3) {
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final result = await _polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(
            currentLatLng.latitude,
            currentLatLng.longitude,
          ),
          destination: PointLatLng(
            _destination.latitude,
            _destination.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );

      debugPrint('Polyline status: ${result.status}');
      debugPrint('Polyline errorMessage: ${result.errorMessage}');
      debugPrint('Polyline points count: ${result.points.length}');

      if (result.points.isNotEmpty) {
        final polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          points: polylineCoordinates,
          width: 6,
          color: Colors.blue,
        );

        if (!mounted) return;
        setState(() {
          _polylines
            ..clear()
            ..add(polyline);
          _routeDebugMessage = 'Route loaded: ${result.points.length} points';
          _lastPolylineOrigin = currentLatLng;
        });
      } else {
        final fallbackPolyline = Polyline(
          polylineId: const PolylineId('fallback_route'),
          points: <LatLng>[currentLatLng, _destination],
          width: 5,
          color: Colors.red,
        );

        if (!mounted) return;
        setState(() {
          _polylines
            ..clear()
            ..add(fallbackPolyline);
          _routeDebugMessage =
              'No route points returned. Showing fallback straight line.';
          _lastPolylineOrigin = currentLatLng;
        });
      }
    } catch (e) {
      debugPrint('Polyline exception: $e');

      final fallbackPolyline = Polyline(
        polylineId: const PolylineId('fallback_route_exception'),
        points: <LatLng>[currentLatLng, _destination],
        width: 5,
        color: Colors.red,
      );

      if (!mounted) return;
      setState(() {
        _polylines
          ..clear()
          ..add(fallbackPolyline);
        _routeDebugMessage =
            'Polyline exception occurred. Showing fallback straight line.';
        _lastPolylineOrigin = currentLatLng;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  Future<void> _moveCamera(LatLng target) async {
    if (!_mapController.isCompleted) return;

    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: 16,
        ),
      ),
    );
  }

  void _checkIfReached(LatLng currentLatLng) {
    if (_hasShownReachedDialog) return;

    final distance = _calculateDistanceInMeters(
      currentLatLng.latitude,
      currentLatLng.longitude,
      _destination.latitude,
      _destination.longitude,
    );
debugPrint('Distance to destination: $distance');
    if (distance <= 30) {
      _hasShownReachedDialog = true;
      _showReachedDialog();
    }
  }

  double _calculateDistanceInMeters(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const double earthRadius = 6371000;

    final dLat = _toRadians(endLat - startLat);
    final dLng = _toRadians(endLng - startLng);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(startLat)) *
            cos(_toRadians(endLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  void _showReachedDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reached'),
          content: const Text('You have reached the destination.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                final controller = context.read<DriverTrackingController>();
                await controller.stopTracking();

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DriverTrackingController>();
    final location = controller.currentLocation;

    final initialCameraPosition = CameraPosition(
      target: location != null
          ? LatLng(location.latitude, location.longitude)
          : _destination,
      zoom: 15,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
      ),
      body: Column(
        children: [
         
          if (!controller.isTracking)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.all(10),
              child: const Text(
                'Tracking is currently stopped',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: initialCameraPosition,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}