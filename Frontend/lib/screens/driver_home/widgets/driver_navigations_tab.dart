import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../utils/navigation_mixin.dart';
import 'navigation_card.dart';
import 'create_navigation_sheet.dart';

class DriverNavigationsTab extends StatefulWidget {
  final List<AmbulanceNavigation>? navigations;
  final Future<void> Function() onRefresh;
  final Future<bool> Function({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    String? vehicleNumber,
  }) onCreateNavigation;
  final Future<bool> Function(int navigationId) onStartRide;
  final Future<bool> Function(int navigationId) onEndRide;
  final Future<bool> Function(int navigationId) onDeleteNavigation;
  final int? activeNavigationId;
  final bool isPublishing;

  const DriverNavigationsTab({
    super.key,
    required this.navigations,
    required this.onRefresh,
    required this.onCreateNavigation,
    required this.onStartRide,
    required this.onEndRide,
    required this.onDeleteNavigation,
    this.activeNavigationId,
    this.isPublishing = false,
  });

  @override
  State<DriverNavigationsTab> createState() => _DriverNavigationsTabState();
}

class _DriverNavigationsTabState extends State<DriverNavigationsTab>
    with NavigationMixin {
  Future<void> _showCreateSheet() async {
    final result = await CreateNavigationSheet.show(
      context,
      onSubmit: widget.onCreateNavigation,
    );

    if (result == true && mounted) {
      showSuccessSnackbar(context, 'Navigation created successfully');
    } else if (result == false && mounted) {
      showErrorSnackbar(context, 'Failed to create navigation');
    }
  }

  Future<void> _handleStartRide(AmbulanceNavigation navigation) async {
    if (navigation.id == null) return;

    final success = await widget.onStartRide(navigation.id!);

    if (mounted) {
      if (success) {
        showSuccessSnackbar(context, 'Ride started - Live tracking enabled');
      } else {
        showErrorSnackbar(context, 'Failed to start ride. Check GPS permissions.');
      }
    }
  }

  Future<void> _handleEndRide(AmbulanceNavigation navigation) async {
    if (navigation.id == null) return;

    final success = await widget.onEndRide(navigation.id!);

    if (mounted) {
      if (success) {
        showSuccessSnackbar(context, 'Ride completed');
      } else {
        showErrorSnackbar(context, 'Failed to end ride');
      }
    }
  }

  void _handleDelete(AmbulanceNavigation navigation) {
    if (navigation.id == null) return;

    showAlertDialogBox(
      context,
      title: 'Delete Navigation',
      message: 'Are you sure you want to delete this navigation?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      onConfirm: () async {
        final success = await widget.onDeleteNavigation(navigation.id!);
        if (mounted) {
          if (success) {
            showSuccessSnackbar(context, 'Navigation deleted');
          } else {
            showErrorSnackbar(context, 'Failed to delete navigation');
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigations = widget.navigations;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: navigations == null || navigations.isEmpty
            ? _buildEmptyState(theme)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: navigations.length,
                itemBuilder: (context, index) {
                  final navigation = navigations[index];
                  final isActiveNavigation =
                      navigation.id == widget.activeNavigationId;
                  return NavigationCard(
                    navigation: navigation,
                    onStartRide: () => _handleStartRide(navigation),
                    onEndRide: () => _handleEndRide(navigation),
                    onDelete: () => _handleDelete(navigation),
                    isPublishing: isActiveNavigation && widget.isPublishing,
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        icon: const Icon(Icons.add),
        label: const Text('New Navigation'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.navigation_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Navigations Yet',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first navigation to get started',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
