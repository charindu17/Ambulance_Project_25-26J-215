import 'package:flutter/material.dart';
import '../../../../models/models.dart';

class AmbulanceListCard extends StatelessWidget {
  final AmbulanceNavigation navigation;
  final VoidCallback onTrackPressed;

  const AmbulanceListCard({
    super.key,
    required this.navigation,
    required this.onTrackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ambulance icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_hospital,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        navigation.vehicleNumber ?? 'Ambulance',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'In Transit',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Live badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Location info
            _LocationInfo(
              icon: Icons.trip_origin,
              iconColor: Colors.green,
              label: 'From',
              lat: navigation.startLocation?.lat,
              lng: navigation.startLocation?.lng,
            ),
            const SizedBox(height: 8),
            _LocationInfo(
              icon: Icons.location_on,
              iconColor: Colors.red,
              label: 'To',
              lat: navigation.endLocation?.lat,
              lng: navigation.endLocation?.lng,
            ),
            const SizedBox(height: 16),
            // Track button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTrackPressed,
                icon: const Icon(Icons.gps_fixed),
                label: const Text('Track Live Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationInfo extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final double? lat;
  final double? lng;

  const _LocationInfo({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.lat,
    this.lng,
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
            lat != null && lng != null
                ? '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}'
                : 'Unknown',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
