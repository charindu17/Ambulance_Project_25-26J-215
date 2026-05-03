import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/navigation_mixin.dart';
import '../auth/patient_login_screen.dart';
import 'driver_home_view_model.dart';
import 'widgets/driver_home_container.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with NavigationMixin {
  final DriverHomeViewModel _viewModel = DriverHomeViewModel();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _viewModel.init();
    _viewModel.addListener(_onViewModelChanged);
  }

  /// Request location permission when the app starts
  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, show dialog
      if (mounted) {
        _showLocationServiceDialog();
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showPermissionDeniedSnackbar();
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showPermissionPermanentlyDeniedDialog();
      }
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Location services are required for navigation features. '
          'Please enable location services in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location permission is required for navigation features'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission has been permanently denied. '
          'Please enable it in your device settings to use navigation features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleLogout() async {
    await _viewModel.logout();
    if (!mounted) return;
    pushAndRemoveAll(context, const PatientLoginScreen());
  }

  void _showLogoutDialog() {
    showAlertDialogBox(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      onConfirm: _handleLogout,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel.isLoading || _viewModel.driver == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DriverHomeContainer(
      driver: _viewModel.driver!,
      navigations: _viewModel.navigations,
      onRefresh: _viewModel.loadNavigations,
      onCreateNavigation: _viewModel.createNavigation,
      onStartRide: _viewModel.startRide,
      onEndRide: _viewModel.endRide,
      onDeleteNavigation: _viewModel.deleteNavigation,
      onLogoutRequested: _showLogoutDialog,
      activeNavigationId: _viewModel.activeNavigationId,
      isPublishing: _viewModel.isPublishing,
    );
  }
}
