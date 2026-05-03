import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../../services/services.dart';

class DriverHomeViewModel extends ChangeNotifier {
  final AmbulanceNavigationService _navigationService =
      AmbulanceNavigationService();
  final LocationPublisherService _locationPublisher =
      LocationPublisherService();
  final PushNotificationSenderService _notificationSender =
      PushNotificationSenderService();

  Driver? _driver;
  List<AmbulanceNavigation>? _navigations;
  bool _isLoading = true;
  String? _error;
  int? _activeNavigationId;

  Driver? get driver => _driver;
  List<AmbulanceNavigation>? get navigations => _navigations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get activeNavigationId => _activeNavigationId;
  bool get isPublishing => _locationPublisher.isPublishing;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final storageService = await StorageService.getInstance();
      _driver = storageService.getDriver();

      if (_driver?.id != null) {
        await loadNavigations();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNavigations() async {
    if (_driver?.id == null) return;

    try {
      final response = await _navigationService.getDriverNavigations(
        _driver!.id!,
      );

      if (response.isSuccess) {
        _navigations = response.navigations;
        _error = null;
      } else {
        _error = response.error;
      }
    } catch (e) {
      _error = e.toString();
    }

    notifyListeners();
  }

  Future<bool> createNavigation({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    String? vehicleNumber,
  }) async {
    if (_driver?.id == null) return false;

    try {
      final response = await _navigationService.createNavigation(
        driverId: _driver!.id!,
        startLatitude: startLatitude,
        startLongitude: startLongitude,
        endLatitude: endLatitude,
        endLongitude: endLongitude,
        vehicleNumber: vehicleNumber ?? _driver?.vehicleNumber,
      );

      if (response.isSuccess) {
        await loadNavigations();
        return true;
      } else {
        _error = response.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Start a ride: Update status to STARTED and begin location publishing.
  Future<bool> startRide(int navigationId) async {
    try {
      // Find the navigation to get its details for MQTT discovery
      final navigation = _navigations?.firstWhere(
        (n) => n.id == navigationId,
        orElse: () => AmbulanceNavigation(),
      );

      // First update the status to STARTED
      final response = await _navigationService.updateStatus(
        navigationId,
        status: 'STARTED',
      );

      if (!response.isSuccess) {
        _error = response.error;
        notifyListeners();
        return false;
      }

      // Start publishing location (also broadcasts to discovery topic)
      final publishingStarted = await _locationPublisher.startPublishing(
        navigationId,
        navigation: navigation,
      );

      if (publishingStarted) {
        _activeNavigationId = navigationId;

        // Send push notification to all patients
        _notificationSender.sendAmbulanceArrivingNotification(
          navigationId: navigationId,
          vehicleNumber: navigation?.vehicleNumber ?? _driver?.vehicleNumber,
          driverName: _driver?.name,
        );
      } else {
        _error =
            'Failed to start location tracking. Please check GPS permissions.';
      }

      await loadNavigations();
      return publishingStarted;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// End a ride: Stop location publishing and update status to COMPLETED.
  Future<bool> endRide(int navigationId) async {
    try {
      // Stop publishing location
      _locationPublisher.stopPublishing();
      _activeNavigationId = null;

      // Update status to COMPLETED
      final response = await _navigationService.updateStatus(
        navigationId,
        status: 'COMPLETED',
      );

      if (response.isSuccess) {
        await loadNavigations();
        return true;
      } else {
        _error = response.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(int navigationId, String status) async {
    try {
      final response = await _navigationService.updateStatus(
        navigationId,
        status: status,
      );

      if (response.isSuccess) {
        await loadNavigations();
        return true;
      } else {
        _error = response.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNavigation(int navigationId) async {
    try {
      // If deleting the active navigation, stop publishing first
      if (_activeNavigationId == navigationId) {
        _locationPublisher.stopPublishing();
        _activeNavigationId = null;
      }

      final response = await _navigationService.deleteNavigation(navigationId);

      if (response.isSuccess) {
        await loadNavigations();
        return true;
      } else {
        _error = response.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    // Stop any active location publishing
    _locationPublisher.stopPublishing();
    _activeNavigationId = null;

    final storageService = await StorageService.getInstance();
    await storageService.clearDriver();
  }

  @override
  void dispose() {
    _locationPublisher.dispose();
    super.dispose();
  }
}
