import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../models/models.dart';
import '../../../../services/services.dart';

class LiveAmbulanceTrackingScreen extends StatefulWidget {
  final AmbulanceNavigation navigation;

  const LiveAmbulanceTrackingScreen({
    super.key,
    required this.navigation,
  });

  static Future<void> show(
    BuildContext context,
    AmbulanceNavigation navigation,
  ) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveAmbulanceTrackingScreen(navigation: navigation),
      ),
    );
  }

  @override
  State<LiveAmbulanceTrackingScreen> createState() =>
      _LiveAmbulanceTrackingScreenState();
}

class _LiveAmbulanceTrackingScreenState
    extends State<LiveAmbulanceTrackingScreen> {
  final MqttService _mqttService = MqttService();
  GoogleMapController? _mapController;
  StreamSubscription<String>? _locationSubscription;

  LatLng? _ambulanceLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isConnected = false;
  bool _isConnecting = true;

  LatLng? get _startLatLng {
    final start = widget.navigation.startLocation;
    if (start?.lat != null && start?.lng != null) {
      return LatLng(start!.lat!, start.lng!);
    }
    return null;
  }

  LatLng? get _endLatLng {
    final end = widget.navigation.endLocation;
    if (end?.lat != null && end?.lng != null) {
      return LatLng(end!.lat!, end.lng!);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _setupInitialMarkers();
    _connectAndSubscribe();
  }

  void _setupInitialMarkers() {
    final markers = <Marker>{};
    final polylineCoordinates = <LatLng>[];

    if (_startLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: _startLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start Location'),
        ),
      );
      polylineCoordinates.add(_startLatLng!);
    }

    if (_endLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: _endLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
      polylineCoordinates.add(_endLatLng!);
    }

    setState(() {
      _markers = markers;
      if (polylineCoordinates.length == 2) {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.grey,
            width: 3,
            patterns: [PatternItem.dash(15), PatternItem.gap(10)],
          ),
        };
      }
    });
  }

  Future<void> _connectAndSubscribe() async {
    setState(() => _isConnecting = true);

    try {
      final connected = await _mqttService.connect();
      setState(() {
        _isConnected = connected;
        _isConnecting = false;
      });

      if (connected && widget.navigation.id != null) {
        final topic = 'ambulance/location/${widget.navigation.id}';
        _locationSubscription = _mqttService.subscribe(topic).listen(
          _handleLocationUpdate,
          onError: (error) {
            setState(() => _isConnected = false);
          },
        );
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
      });
    }
  }

  void _handleLocationUpdate(String message) {
    final parts = message.split(',');
    if (parts.length != 2) return;

    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return;

    setState(() {
      _ambulanceLocation = LatLng(lat, lng);
      _updateMarkers();
    });

    // Animate camera to follow ambulance
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(_ambulanceLocation!),
    );
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    // Start marker (green)
    if (_startLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: _startLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start Location'),
        ),
      );
    }

    // End marker (red)
    if (_endLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: _endLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }

    // Ambulance marker (blue, live)
    if (_ambulanceLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('ambulance'),
          position: _ambulanceLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: 'Ambulance',
            snippet: widget.navigation.vehicleNumber ?? 'Live Location',
          ),
        ),
      );
    }

    _markers = markers;
  }

  void _fitBounds() {
    if (_mapController == null) return;

    final points = <LatLng>[];
    if (_startLatLng != null) points.add(_startLatLng!);
    if (_endLatLng != null) points.add(_endLatLng!);
    if (_ambulanceLocation != null) points.add(_ambulanceLocation!);

    if (points.length < 2) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialPosition = _ambulanceLocation ?? _startLatLng ?? _endLatLng;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.navigation.vehicleNumber ?? 'Track Ambulance'),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildConnectionStatus(theme),
          ),
        ],
      ),
      body: initialPosition == null
          ? const Center(child: Text('No location data available'))
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initialPosition,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    Future.delayed(
                      const Duration(milliseconds: 500),
                      _fitBounds,
                    );
                  },
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                ),
                // Bottom info card
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _buildInfoCard(theme),
                ),
                // Fit bounds button
                Positioned(
                  bottom: 180,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'fitBounds',
                    onPressed: _fitBounds,
                    child: const Icon(Icons.fit_screen),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildConnectionStatus(ThemeData theme) {
    if (_isConnecting) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _isConnected
            ? Colors.green.withValues(alpha: 0.1)
            : theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green : theme.colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isConnected ? 'Live' : 'Offline',
            style: theme.textTheme.labelSmall?.copyWith(
              color: _isConnected ? Colors.green : theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_hospital,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.navigation.vehicleNumber ?? 'Ambulance',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _ambulanceLocation != null
                            ? 'Location updating...'
                            : 'Waiting for location...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_ambulanceLocation != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.gps_fixed,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_ambulanceLocation!.latitude.toStringAsFixed(6)}, ${_ambulanceLocation!.longitude.toStringAsFixed(6)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    if (widget.navigation.id != null) {
      _mqttService.unsubscribe('ambulance/location/${widget.navigation.id}');
    }
    _mapController?.dispose();
    super.dispose();
  }
}
