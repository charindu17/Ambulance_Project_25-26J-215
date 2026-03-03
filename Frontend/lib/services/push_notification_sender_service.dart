import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Service for sending push notifications to patients via the backend.
class PushNotificationSenderService {
  final ApiClient _client;

  PushNotificationSenderService({ApiClient? client})
      : _client = client ?? ApiClient();

  /// Send notification to specific patients by their IDs.
  Future<bool> sendToPatients({
    required List<int> patientIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final requestBody = {
        'patient_ids': patientIds,
        'title': title,
        'body': body,
        if (data != null) 'data': data,
      };

      final response = await _client.post(
        '/notifications/send',
        body: requestBody,
      );

      if (response is Map && response.containsKey('error')) {
        debugPrint('Failed to send notification: ${response['error']}');
        return false;
      }

      debugPrint('Notification sent to ${patientIds.length} patients');
      return true;
    } catch (e) {
      debugPrint('Error sending notification: $e');
      return false;
    }
  }

  /// Send notification to all patients with FCM tokens.
  Future<bool> sendToAllPatients({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final requestBody = {
        'title': title,
        'body': body,
        if (data != null) 'data': data,
      };

      final response = await _client.post(
        '/notifications/send-all',
        body: requestBody,
      );

      if (response is Map && response.containsKey('error')) {
        debugPrint('Failed to send notification: ${response['error']}');
        return false;
      }

      debugPrint('Notification sent to all patients');
      return true;
    } catch (e) {
      debugPrint('Error sending notification: $e');
      return false;
    }
  }

  /// Send ambulance arriving notification to all patients.
  Future<bool> sendAmbulanceArrivingNotification({
    String? vehicleNumber,
    String? driverName,
  }) async {
    final title = 'Ambulance is on the way!';
    final body = vehicleNumber != null
        ? 'Ambulance $vehicleNumber is now active and heading to destination via your route.'
        : 'An ambulance is now active and on its way.';

    return sendToAllPatients(
      title: title,
      body: body,
      data: {
        'type': 'ambulance_arriving',
        if (vehicleNumber != null) 'vehicle_number': vehicleNumber,
        if (driverName != null) 'driver_name': driverName,
      },
    );
  }
}
