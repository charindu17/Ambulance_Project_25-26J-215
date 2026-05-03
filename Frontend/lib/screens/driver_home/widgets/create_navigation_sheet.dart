import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../widgets/widgets.dart';
import 'map_location_picker.dart';

class CreateNavigationSheet extends StatefulWidget {
  final Future<bool> Function({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    String? vehicleNumber,
  }) onSubmit;

  const CreateNavigationSheet({
    super.key,
    required this.onSubmit,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Future<bool> Function({
      required double startLatitude,
      required double startLongitude,
      required double endLatitude,
      required double endLongitude,
      String? vehicleNumber,
    }) onSubmit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => CreateNavigationSheet(onSubmit: onSubmit),
    );
  }

  @override
  State<CreateNavigationSheet> createState() => _CreateNavigationSheetState();
}

class _CreateNavigationSheetState extends State<CreateNavigationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();

  LatLng? _startLocation;
  LatLng? _endLocation;
  bool _isLoading = false;

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickStartLocation() async {
    final result = await MapLocationPicker.show(
      context,
      initialLocation: _startLocation,
      title: 'Pick Start Location',
    );

    if (result != null && mounted) {
      setState(() {
        _startLocation = result;
      });
    }
  }

  Future<void> _pickEndLocation() async {
    final result = await MapLocationPicker.show(
      context,
      initialLocation: _endLocation,
      title: 'Pick End Location',
    );

    if (result != null && mounted) {
      setState(() {
        _endLocation = result;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_startLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start location')),
      );
      return;
    }

    if (_endLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an end location')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await widget.onSubmit(
        startLatitude: _startLocation!.latitude,
        startLongitude: _startLocation!.longitude,
        endLatitude: _endLocation!.latitude,
        endLongitude: _endLocation!.longitude,
        vehicleNumber: _vehicleNumberController.text.isNotEmpty
            ? _vehicleNumberController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context, success);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildLocationCard({
    required String title,
    required LatLng? location,
    required VoidCallback onTap,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (location != null)
                      Text(
                        '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Text(
                        'Tap to select on map',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                location != null ? Icons.check_circle : Icons.chevron_right,
                color: location != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Create Navigation',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Select pickup and drop-off locations from the map',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildLocationCard(
                title: 'Start Location (Pickup)',
                location: _startLocation,
                onTap: _pickStartLocation,
                icon: Icons.trip_origin,
                iconColor: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildLocationCard(
                title: 'End Location (Drop-off)',
                location: _endLocation,
                onTap: _pickEndLocation,
                icon: Icons.location_on,
                iconColor: Colors.red,
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _vehicleNumberController,
                labelText: 'Vehicle Number (Optional)',
                hintText: 'e.g. ABC-1234',
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.directions_car_outlined),
              ),
              const SizedBox(height: 24),
              AppLoadingButton(
                text: 'Create Navigation',
                isLoading: _isLoading,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
