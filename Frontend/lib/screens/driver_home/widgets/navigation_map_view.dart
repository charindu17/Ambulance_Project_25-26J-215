import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/models.dart';

class NavigationMapView extends StatefulWidget {
  final AmbulanceNavigation navigation;

  const NavigationMapView({
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
        builder: (context) => NavigationMapView(navigation: navigation),
      ),
    );
  }

  @override
  State<NavigationMapView> createState() => _NavigationMapViewState();
}

class _NavigationMapViewState extends State<NavigationMapView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

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
    _setupMapData();
  }

  void _setupMapData() {
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
          infoWindow: const InfoWindow(title: 'End Location'),
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
            color: Colors.blue,
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        };
      }
    });
  }

  void _fitBounds() {
    if (_startLatLng == null || _endLatLng == null || _mapController == null) {
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(
        _startLatLng!.latitude < _endLatLng!.latitude
            ? _startLatLng!.latitude
            : _endLatLng!.latitude,
        _startLatLng!.longitude < _endLatLng!.longitude
            ? _startLatLng!.longitude
            : _endLatLng!.longitude,
      ),
      northeast: LatLng(
        _startLatLng!.latitude > _endLatLng!.latitude
            ? _startLatLng!.latitude
            : _endLatLng!.latitude,
        _startLatLng!.longitude > _endLatLng!.longitude
            ? _startLatLng!.longitude
            : _endLatLng!.longitude,
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  Future<void> _openInGoogleMaps() async {
    if (_startLatLng == null || _endLatLng == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_startLatLng!.latitude},${_startLatLng!.longitude}'
      '&destination=${_endLatLng!.latitude},${_endLatLng!.longitude}'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'STARTED':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigation = widget.navigation;

    if (_startLatLng == null && _endLatLng == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Navigation Map')),
        body: const Center(
          child: Text('No location data available'),
        ),
      );
    }

    final initialPosition = _startLatLng ?? _endLatLng!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions),
            tooltip: 'Open in Google Maps',
            onPressed: _openInGoogleMaps,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              Future.delayed(const Duration(milliseconds: 500), _fitBounds);
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(navigation.status)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getStatusColor(navigation.status),
                            ),
                          ),
                          child: Text(
                            navigation.status ?? 'PENDING',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _getStatusColor(navigation.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (navigation.vehicleNumber != null)
                          Text(
                            navigation.vehicleNumber!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_startLatLng != null)
                      _LocationInfo(
                        icon: Icons.trip_origin,
                        iconColor: Colors.green,
                        label: 'Start',
                        location: _startLatLng!,
                      ),
                    if (_startLatLng != null && _endLatLng != null)
                      const SizedBox(height: 8),
                    if (_endLatLng != null)
                      _LocationInfo(
                        icon: Icons.location_on,
                        iconColor: Colors.red,
                        label: 'End',
                        location: _endLatLng!,
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openInGoogleMaps,
                        icon: const Icon(Icons.navigation),
                        label: const Text('Start Navigation'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _LocationInfo extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final LatLng location;

  const _LocationInfo({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
