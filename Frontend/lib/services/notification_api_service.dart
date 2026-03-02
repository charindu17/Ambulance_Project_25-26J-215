import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Service for notification-related API calls including acknowledgments.
class NotificationApiService {
  final ApiClient _client;

  NotificationApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Acknowledge an ambulance notification.
  ///
  /// [navigationId] - The ID of the ambulance navigation/trip
  /// [patientId] - The ID of the patient acknowledging
  /// [acknowledgmentType] - Type of acknowledgment: 'SEEN', 'AWARE', or 'MOVING_ASIDE'
  ///
  /// Returns the acknowledgment data on success, or error map on failure.
  Future<Map<String, dynamic>> acknowledgeNotification({
    required int navigationId,
    required int patientId,
    String acknowledgmentType = 'AWARE',
  }) async {
    try {
      final response = await _client.post(
        '/notifications/acknowledge',
        body: {
          'navigation_id': navigationId,
          'patient_id': patientId,
          'acknowledgment_type': acknowledgmentType,
        },
      );

      if (response is Map<String, dynamic>) {
        if (response.containsKey('error')) {
          debugPrint('Failed to acknowledge notification: ${response['error']}');
        } else {
          debugPrint('Notification acknowledged successfully');
        }
        return response;
      }

      return {'error': 'Invalid response format'};
    } catch (e) {
      debugPrint('Error acknowledging notification: $e');
      return {'error': e.toString()};
    }
  }

  /// Get all acknowledgments for a specific navigation/ambulance trip.
  ///
  /// [navigationId] - The ID of the ambulance navigation/trip
  ///
  /// Returns acknowledgments data on success, or error map on failure.
  Future<Map<String, dynamic>> getNavigationAcknowledgments(int navigationId) async {
    try {
      final response = await _client.get(
        '/notifications/navigation/$navigationId/acknowledgments',
      );

      if (response is Map<String, dynamic>) {
        if (response.containsKey('error')) {
          debugPrint('Failed to get acknowledgments: ${response['error']}');
        }
        return response;
      }

      return {'error': 'Invalid response format'};
    } catch (e) {
      debugPrint('Error getting acknowledgments: $e');
      return {'error': e.toString()};
    }
  }

  /// Send ambulance alert to specific patients.
  ///
  /// [patientIds] - List of patient IDs to send the alert to
  /// [navigationId] - The ID of the ambulance navigation/trip
  /// [vehicleNumber] - The ambulance vehicle number
  /// [message] - Optional custom message
  ///
  /// Returns response data on success, or error map on failure.
  Future<Map<String, dynamic>> sendAmbulanceAlert({
    required List<int> patientIds,
    required int navigationId,
    required String vehicleNumber,
    String? message,
  }) async {
    try {
      final body = {
        'patient_ids': patientIds,
        'navigation_id': navigationId,
        'vehicle_number': vehicleNumber,
        if (message != null) 'message': message,
      };

      final response = await _client.post(
        '/notifications/send-ambulance-alert',
        body: body,
      );

      if (response is Map<String, dynamic>) {
        if (response.containsKey('error')) {
          debugPrint('Failed to send ambulance alert: ${response['error']}');
        } else {
          debugPrint('Ambulance alert sent successfully');
        }
        return response;
      }

      return {'error': 'Invalid response format'};
    } catch (e) {
      debugPrint('Error sending ambulance alert: $e');
      return {'error': e.toString()};
    }
  }

  /// Get all patients (for driver/admin to send alerts).
  ///
  /// [page] - Optional page number for pagination
  /// [perPage] - Optional items per page for pagination
  ///
  /// Returns patients data on success, or error map on failure.
  Future<Map<String, dynamic>> getAllPatients({int? page, int? perPage}) async {
    try {
      String endpoint = '/patient';
      final queryParams = <String, String>{};

      if (page != null) queryParams['page'] = page.toString();
      if (perPage != null) queryParams['per_page'] = perPage.toString();

      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final response = await _client.get(endpoint);

      if (response is Map<String, dynamic>) {
        if (response.containsKey('error')) {
          debugPrint('Failed to get patients: ${response['error']}');
        }
        return response;
      }

      return {'error': 'Invalid response format'};
    } catch (e) {
      debugPrint('Error getting patients: $e');
      return {'error': e.toString()};
    }
  }
}
