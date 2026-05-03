import 'package:flutter/material.dart';
import '../../../models/models.dart';
import 'driver_navigations_tab.dart';
import 'driver_profile_tab.dart';

class DriverHomeContainer extends StatefulWidget {
  final Driver driver;
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
  final VoidCallback onLogoutRequested;
  final int? activeNavigationId;
  final bool isPublishing;

  const DriverHomeContainer({
    super.key,
    required this.driver,
    required this.navigations,
    required this.onRefresh,
    required this.onCreateNavigation,
    required this.onStartRide,
    required this.onEndRide,
    required this.onDeleteNavigation,
    required this.onLogoutRequested,
    this.activeNavigationId,
    this.isPublishing = false,
  });

  @override
  State<DriverHomeContainer> createState() => _DriverHomeContainerState();
}

class _DriverHomeContainerState extends State<DriverHomeContainer> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DriverNavigationsTab(
            navigations: widget.navigations,
            onRefresh: widget.onRefresh,
            onCreateNavigation: widget.onCreateNavigation,
            onStartRide: widget.onStartRide,
            onEndRide: widget.onEndRide,
            onDeleteNavigation: widget.onDeleteNavigation,
            activeNavigationId: widget.activeNavigationId,
            isPublishing: widget.isPublishing,
          ),
          DriverProfileTab(driver: widget.driver),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildAppBar() {
    final titles = ['Navigations', 'Profile'];

    return AppBar(
      title: Text(titles[_currentIndex]),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: widget.onLogoutRequested,
        ),
      ],
    );
  }

  NavigationBar _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.navigation_outlined),
          selectedIcon: Icon(Icons.navigation),
          label: 'Navigations',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
