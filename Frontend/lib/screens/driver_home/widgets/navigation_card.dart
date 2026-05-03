import 'package:flutter/material.dart';
import '../../../models/models.dart';
import 'navigation_map_view.dart';

class NavigationCard extends StatelessWidget {
  final AmbulanceNavigation navigation;
  final VoidCallback? onStartRide;
  final VoidCallback? onEndRide;
  final VoidCallback onDelete;
  final bool isPublishing;

  const NavigationCard({
    super.key,
    required this.navigation,
    this.onStartRide,
    this.onEndRide,
    required this.onDelete,
    this.isPublishing = false,
  });

  Color _getStatusColor(BuildContext context, String? status) {
    final theme = Theme.of(context);
    switch (status?.toUpperCase()) {
      case 'STARTED':
        return theme.colorScheme.primary;
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toUpperCase()) {
      case 'STARTED':
        return Icons.directions_car;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'PENDING':
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(context, navigation.status);
    final status = navigation.status?.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(navigation.status),
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        navigation.status ?? 'PENDING',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Live indicator for STARTED status
                if (status == 'STARTED' && isPublishing) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
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
                        const SizedBox(width: 4),
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
                const Spacer(),
                if (navigation.vehicleNumber != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          navigation.vehicleNumber!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _LocationRow(
              icon: Icons.trip_origin,
              iconColor: Colors.green,
              label: 'Start',
              lat: navigation.startLocation?.lat,
              lng: navigation.startLocation?.lng,
            ),
            const SizedBox(height: 8),
            _LocationRow(
              icon: Icons.location_on,
              iconColor: Colors.red,
              label: 'End',
              lat: navigation.endLocation?.lat,
              lng: navigation.endLocation?.lng,
            ),
            if (navigation.createdAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    navigation.createdAt!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _buildActionButtons(context, theme, status),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, ThemeData theme, String? status) {
    return Row(
      children: [
        // View Map button - always visible
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => NavigationMapView.show(context, navigation),
            icon: const Icon(Icons.map_outlined),
            label: const Text('View Map'),
          ),
        ),
        const SizedBox(width: 8),
        // Action button based on status
        if (status == 'PENDING' && onStartRide != null)
          Expanded(
            child: FilledButton.icon(
              onPressed: onStartRide,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Ride'),
            ),
          )
        else if (status == 'STARTED' && onEndRide != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEndRide,
              icon: const Icon(Icons.stop),
              label: const Text('End Ride'),
            ),
          ),
        // Delete button - only for non-started rides or completed
        if (status != 'STARTED') ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            color: theme.colorScheme.error,
            tooltip: 'Delete',
          ),
        ],
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final double? lat;
  final double? lng;

  const _LocationRow({
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
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            lat != null && lng != null
                ? '${lat!.toStringAsFixed(6)}, ${lng!.toStringAsFixed(6)}'
                : '--',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
