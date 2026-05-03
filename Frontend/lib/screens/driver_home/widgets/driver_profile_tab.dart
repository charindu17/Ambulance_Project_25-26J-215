import 'package:flutter/material.dart';
import '../../../models/models.dart';

class DriverProfileTab extends StatelessWidget {
  final Driver driver;

  const DriverProfileTab({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeSection(driverName: driver.name),
          const SizedBox(height: 24),
          _DriverProfileCard(driver: driver),
        ],
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  final String? driverName;

  const _WelcomeSection({this.driverName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome,',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          driverName ?? 'Driver',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _DriverProfileCard extends StatelessWidget {
  final Driver driver;

  const _DriverProfileCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Profile',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Name',
              value: driver.name ?? '--',
            ),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: driver.email ?? '--',
            ),
            _InfoRow(
              icon: Icons.directions_car_outlined,
              label: 'Vehicle Number',
              value: driver.vehicleNumber ?? '--',
            ),
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'NIC',
              value: driver.nic ?? '--',
            ),
            if (driver.staffId != null && driver.staffId!.isNotEmpty)
              _InfoRow(
                icon: Icons.work_outline,
                label: 'Staff ID',
                value: driver.staffId!,
              ),
            if (driver.createdAt != null)
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Member Since',
                value: driver.createdAt!,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
