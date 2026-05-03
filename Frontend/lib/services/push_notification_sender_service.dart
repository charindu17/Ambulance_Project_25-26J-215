import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Service for sending push notifications to patients via the backend.
class PushNotificationSenderService {
  final ApiClient _client;

  PushNotificationSenderService({ApiClient? client})
      : _client = client ?? ApiClient();

  /// Send notification to specific patients by their IDs.
  /// [dataOnly] — if true, sends only a data payload (no OS-level notification banner).
  Future<bool> sendToPatients({
    required List<int> patientIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    bool dataOnly = false,
  }) async {
    try {
      final requestBody = {
        'patient_ids': patientIds,
        'title': title,
        'body': body,
        if (data != null) 'data': data,
        'data_only': dataOnly,
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
    bool dataOnly = false,
  }) async {
    try {
      final requestBody = {
        'title': title,
        'body': body,
        if (data != null) 'data': data,
        'data_only': dataOnly,
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
  /// Uses type AMBULANCE_ALERT and dataOnly so the patient foreground
  /// handler shows the with-buttons Notification A without an OS duplicate.
  Future<bool> sendAmbulanceArrivingNotification({
    required int navigationId,             // needed by _parseAmbulanceAlertData
    String? vehicleNumber,
    String? driverName,
  }) async {
    // ── CONTENT: update header & body strings here ──────────────────────────
    final title = 'Ambulance On The Way';
    final body = vehicleNumber != null
        ? 'Ambulance $vehicleNumber is now active and heading to the destination'
        : 'An ambulance is now active and heading to the destination';
    // ────────────────────────────────────────────────────────────────────────

    return sendToAllPatients(
      title: title,
      body: body,
      data: {
        'type': 'AMBULANCE_ALERT',              // triggers with-buttons path
        'navigation_id': navigationId.toString(), // required by _parseAmbulanceAlertData
        'title': title,
        'body': body,
        if (vehicleNumber != null) 'vehicle_number': vehicleNumber,
        if (driverName != null) 'driver_name': driverName,
        'require_acknowledgment': 'true',
      },
      dataOnly: true,                           // no OS-level duplicate banner
    );
  }
}
