import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import 'mqtt_service.dart';

/// Service for publishing live GPS location to MQTT for ambulance tracking.
/// Used by drivers to broadcast their location during active rides.
/// Also handles ambulance discovery by publishing to the active topic.
class LocationPublisherService {
  static const String _discoveryTopic = 'ambulance/active';

  final MqttService _mqttService = MqttService();
  StreamSubscription<Position>? _locationSubscription;
  String? _currentTopic;
  int? _currentNavigationId;
  bool _isPublishing = false;

  bool get isPublishing => _isPublishing;
  String? get currentTopic => _currentTopic;
  int? get currentNavigationId => _currentNavigationId;

  /// Start publishing location updates for a specific navigation.
  /// Also broadcasts to discovery topic so patients can find this ambulance.
  /// Returns true if publishing started successfully.
  Future<bool> startPublishing(
    int navigationId, {
    AmbulanceNavigation? navigation,
  }) async {
    // Check location permissions
    final hasPermission = await _checkPermission();
    if (!hasPermission) return false;

    // Connect to MQTT if not connected
    if (!_mqttService.isConnected) {
      final connected = await _mqttService.connect();
      if (!connected) return false;
    }

    _currentNavigationId = navigationId;
    _currentTopic = 'ambulance/location/$navigationId';
    _isPublishing = true;

    // Broadcast to discovery topic so patients can find this ambulance
    if (navigation != null) {
      _publishDiscoveryAdd(navigation);
    }

    // Configure location settings for driving
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Only update when moved 10+ meters
    );

    // Start location stream
    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (_isPublishing && _currentTopic != null) {
              final message = '${position.latitude},${position.longitude}';
              _mqttService.publish(_currentTopic!, message);
            }
          },
          onError: (error) {
            // Continue publishing even if there's an error
            // The stream will recover automatically
          },
        );

    // Publish initial position immediately
    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final message =
          '${currentPosition.latitude},${currentPosition.longitude}';
      _mqttService.publish(_currentTopic!, message);
    } catch (_) {
      // Ignore initial position error, stream will handle it
    }

    return true;
  }

  /// Publish ADD message to discovery topic.
  /// Format: ADD:{id},{vehicleNumber},{startLat},{startLng},{endLat},{endLng}
  void _publishDiscoveryAdd(AmbulanceNavigation navigation) {
    final startLat = navigation.startLocation?.lat ?? 0;
    final startLng = navigation.startLocation?.lng ?? 0;
    final endLat = navigation.endLocation?.lat ?? 0;
    final endLng = navigation.endLocation?.lng ?? 0;
    final vehicleNumber = navigation.vehicleNumber ?? 'Unknown';

    final message =
        'ADD:${navigation.id},$vehicleNumber,$startLat,$startLng,$endLat,$endLng';
    _mqttService.publish(_discoveryTopic, message);
  }

  /// Publish REMOVE message to discovery topic.
  /// Format: REMOVE:{id}
  void _publishDiscoveryRemove(int navigationId) {
    final message = 'REMOVE:$navigationId';
    _mqttService.publish(_discoveryTopic, message);
  }

  /// Stop publishing location updates.
  /// Also broadcasts removal to discovery topic and disconnects MQTT.
  void stopPublishing() {
    // Broadcast removal to discovery topic
    if (_currentNavigationId != null && _mqttService.isConnected) {
      _publishDiscoveryRemove(_currentNavigationId!);
    }

    _locationSubscription?.cancel();
    _locationSubscription = null;
    _currentTopic = null;
    _currentNavigationId = null;
    _isPublishing = false;

    // Disconnect from MQTT server
    _mqttService.disconnect();
  }

  /// Check and request location permissions.
  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Dispose the service and clean up resources.
  void dispose() {
    stopPublishing();
  }
}
