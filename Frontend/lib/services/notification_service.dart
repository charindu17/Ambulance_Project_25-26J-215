import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_client.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Notification type constants
class NotificationType {
  static const String ambulanceAlert = 'AMBULANCE_ALERT';
  static const String ambulanceArriving = 'ambulance_arriving';
}

/// Action button IDs for ambulance notifications
class NotificationActionId {
  static const String imAware = 'IM_AWARE_ACTION';
  static const String movingAside = 'MOVING_ASIDE_ACTION';
}

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Background message data: ${message.data}');

  // Show local notification with action buttons for ambulance alerts
  final type = message.data['type'];
  if (type == NotificationType.ambulanceAlert || type == NotificationType.ambulanceArriving) {
    await _showBackgroundAmbulanceNotification(message);
  }
}

/// Show ambulance notification from background isolate
Future<void> _showBackgroundAmbulanceNotification(RemoteMessage message) async {
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize for background
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwinSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: darwinSettings,
  );

  await localNotifications.initialize(
    initSettings,
    onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
  );

  final notification = message.notification;
  final title = notification?.title ?? 'Ambulance Approaching!';
  final body = notification?.body ?? 'Please clear the way for the ambulance.';

  const androidDetails = AndroidNotificationDetails(
    'ambulance_alert_channel',
    'Ambulance Alerts',
    channelDescription: 'Emergency notifications for approaching ambulances.',
    importance: Importance.max,
    priority: Priority.max,
    icon: '@mipmap/ic_launcher',
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    actions: [
      AndroidNotificationAction(
        NotificationActionId.imAware,
        "I'm Aware",
        showsUserInterface: true,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        NotificationActionId.movingAside,
        'Moving Aside',
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ],
  );

  const darwinDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.critical,
    categoryIdentifier: 'ambulance_alert_category',
  );

  const details = NotificationDetails(
    android: androidDetails,
    iOS: darwinDetails,
  );

  await localNotifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    details,
    payload: jsonEncode(message.data),
  );
}

/// Background notification response handler - must be top-level function
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  debugPrint('Background notification action: ${response.actionId}');
  debugPrint('Background notification payload: ${response.payload}');

  if (response.payload != null) {
    _handleNotificationAction(response.actionId, response.payload!);
  }
}

/// Handle notification action (works in both foreground and background)
void _handleNotificationAction(String? actionId, String payload) {
  if (actionId == null) return;

  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final navigationIdStr = data['navigation_id'];
    final patientIdStr = data['patient_id'];

    if (navigationIdStr == null) {
      debugPrint('Missing navigation_id in payload');
      return;
    }

    final navigationId = int.tryParse(navigationIdStr.toString());
    final patientId = patientIdStr != null ? int.tryParse(patientIdStr.toString()) : null;

    if (navigationId == null) {
      debugPrint('Invalid navigation_id: $navigationIdStr');
      return;
    }

    String acknowledgmentType;
    switch (actionId) {
      case NotificationActionId.imAware:
        acknowledgmentType = 'AWARE';
        break;
      case NotificationActionId.movingAside:
        acknowledgmentType = 'MOVING_ASIDE';
        break;
      default:
        debugPrint('Unknown action: $actionId');
        return;
    }

    // Send acknowledgment to backend
    _sendAcknowledgmentToBackend(navigationId, patientId, acknowledgmentType);
  } catch (e) {
    debugPrint('Error handling notification action: $e');
  }
}

/// Send acknowledgment to backend (fire and forget for background)
Future<void> _sendAcknowledgmentToBackend(
  int navigationId,
  int? patientId,
  String acknowledgmentType,
) async {
  if (patientId == null) {
    debugPrint('Cannot acknowledge: no patient ID');
    return;
  }

  try {
    final client = ApiClient();
    final response = await client.post(
      '/notifications/acknowledge',
      body: {
        'navigation_id': navigationId,
        'patient_id': patientId,
        'acknowledgment_type': acknowledgmentType,
      },
    );

    if (response is Map && response.containsKey('error')) {
      debugPrint('Acknowledgment failed: ${response['error']}');
    } else {
      debugPrint('Acknowledgment sent successfully: $acknowledgmentType');
    }
  } catch (e) {
    debugPrint('Error sending acknowledgment: $e');
  }
}

/// Service for handling Firebase Cloud Messaging (FCM) push notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiClient _apiClient = ApiClient();

  String? _fcmToken;
  bool _isInitialized = false;
  int? _currentPatientId;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Android notification channel for high importance notifications
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  /// Android notification channel for ambulance alerts (max priority)
  static const AndroidNotificationChannel _ambulanceChannel = AndroidNotificationChannel(
    'ambulance_alert_channel',
    'Ambulance Alerts',
    description: 'Emergency notifications for approaching ambulances.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // NEW: dedicated channel for ALARM notifications — plays the default alarm
  // sound and keeps the screen on so the driver cannot miss it.
  static const AndroidNotificationChannel _alarmChannel = AndroidNotificationChannel(
    'ambulance_alarm_channel',
    'Ambulance Alarm',
    description: 'Urgent alarm for vehicles that have not yielded to an ambulance.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    // sound: RawResourceAndroidNotificationSound('alarm'), // uncomment and
    // add res/raw/alarm.mp3 to play a custom alarm sound file
  );

  /// Initialize the notification service.
  /// Call this after Firebase.initializeApp() and after user logs in.
  Future<void> initialize({int? patientId}) async {
    if (_isInitialized && _currentPatientId == patientId) return;

    _currentPatientId = patientId;

    // Initialize local notifications for foreground display
    await _initLocalNotifications();

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
      provisional: false,
    );

    // NEW: request exact alarm permission for Android 12+ (API 31+)
    if (Platform.isAndroid) {
      final status = await Permission.scheduleExactAlarm.request();
      debugPrint('Exact alarm permission: $status');
    }

    debugPrint('Notification permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Save token to backend if patient ID is provided
      if (patientId != null && _fcmToken != null) {
        await saveTokenToBackend(patientId);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        if (_currentPatientId != null) {
          saveTokenToBackend(_currentPatientId!);
        }
      });

      // Handle foreground messages - show local notification
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Set foreground notification presentation options for iOS
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } else {
      debugPrint('Notification permission denied: ${settings.authorizationStatus}');
    }
  }

  /// Initialize local notifications plugin for foreground display
  Future<void> _initLocalNotifications() async {
    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization with action categories
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'ambulance_alert_category',
          actions: [
            DarwinNotificationAction.plain(
              NotificationActionId.imAware,
              "I'm Aware",
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              NotificationActionId.movingAside,
              'Moving Aside',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
    );

    // Create Android notification channels
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(_channel);
    await androidImplementation?.createNotificationChannel(_ambulanceChannel);
    await androidImplementation?.createNotificationChannel(_alarmChannel); // NEW
  }

  /// Handle foreground notification response (tap or action button)
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification response: ${response.actionId}, payload: ${response.payload}');

    // Check if this is an action button press
    if (response.actionId != null && response.payload != null) {
      _handleNotificationAction(response.actionId, response.payload!);

      // Also trigger callback to show confirmation in UI if needed
      if (response.actionId == NotificationActionId.imAware ||
          response.actionId == NotificationActionId.movingAside) {
        _onAcknowledgmentFromNotification?.call(response.actionId!);
      }
      return;
    }

    // Regular notification tap
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        final type = data['type'];

        // If ambulance alert, trigger the alert callback
        if (type == NotificationType.ambulanceAlert ||
            type == NotificationType.ambulanceArriving) {
          final alertData = _parseAmbulanceAlertDataFromMap(data);
          if (alertData != null) {
            _onAmbulanceAlertReceived?.call(
              'Ambulance Approaching!',
              'Please clear the way.',
              alertData,
            );
            return;
          }
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }

    _onNotificationTap?.call({'payload': response.payload});
  }

  /// Parse ambulance alert data from a Map (used for local notifications)
  AmbulanceAlertData? _parseAmbulanceAlertDataFromMap(Map<String, dynamic> data) {
    try {
      final navigationIdStr = data['navigation_id'];
      final vehicleNumber = data['vehicle_number'];

      if (navigationIdStr == null || vehicleNumber == null) {
        return null;
      }

      final navigationId = int.tryParse(navigationIdStr.toString());
      if (navigationId == null) {
        return null;
      }

      return AmbulanceAlertData(
        navigationId: navigationId,
        vehicleNumber: vehicleNumber.toString(),
        requireAcknowledgment: data['require_acknowledgment'] == 'true',
        clickAction: data['click_action'],
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if a message is an ambulance alert
  bool _isAmbulanceAlert(RemoteMessage message) {
    final type = message.data['type'];
    return type == NotificationType.ambulanceAlert ||
        type == NotificationType.ambulanceArriving;
  }

  /// Parse ambulance alert data from message
  AmbulanceAlertData? _parseAmbulanceAlertData(RemoteMessage message) {
    try {
      final data = message.data;
      final navigationIdStr = data['navigation_id'];
      final vehicleNumber = data['vehicle_number'];

      if (navigationIdStr == null || vehicleNumber == null) {
        debugPrint('Missing required ambulance alert data');
        return null;
      }

      final navigationId = int.tryParse(navigationIdStr.toString());
      if (navigationId == null) {
        debugPrint('Invalid navigation_id: $navigationIdStr');
        return null;
      }

      return AmbulanceAlertData(
        navigationId: navigationId,
        vehicleNumber: vehicleNumber.toString(),
        requireAcknowledgment: data['require_acknowledgment'] == 'true',
        clickAction: data['click_action'],
      );
    } catch (e) {
      debugPrint('Error parsing ambulance alert data: $e');
      return null;
    }
  }

  /// Show a local notification (used for foreground messages)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Use ambulance channel for ambulance alerts
    final isAmbulance = _isAmbulanceAlert(message);
    final channel = isAmbulance ? _ambulanceChannel : _channel;

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: isAmbulance ? Importance.max : Importance.high,
      priority: isAmbulance ? Priority.max : Priority.high,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: isAmbulance,
      category: isAmbulance ? AndroidNotificationCategory.alarm : null,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Show ambulance notification with actions (public method for external use)
  Future<void> showAmbulanceAlertNotification({
    required int navigationId,
    required String vehicleNumber,
    String? title,
    String? body,
  }) async {
    final payloadData = {
      'type': NotificationType.ambulanceAlert,
      'navigation_id': navigationId.toString(),
      'vehicle_number': vehicleNumber,
      if (_currentPatientId != null) 'patient_id': _currentPatientId.toString(),
    };

    const androidDetails = AndroidNotificationDetails(
      'ambulance_alert_channel',
      'Ambulance Alerts',
      channelDescription: 'Emergency notifications for approaching ambulances.',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: [
        AndroidNotificationAction(
          NotificationActionId.imAware,
          "I'm Aware",
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationActionId.movingAside,
          'Moving Aside',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
      categoryIdentifier: 'ambulance_alert_category',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title ?? 'Ambulance Approaching!',
      body ?? 'Vehicle $vehicleNumber is nearby. Please clear the way.',
      details,
      payload: jsonEncode(payloadData),
    );
  }

  /// NEW: Show an ALARM notification for vehicles that have NOT yielded.
  ///
  /// This is triggered when the ML model predicts the vehicle is still
  /// cruising and has not moved aside for the approaching ambulance.
  /// Uses the dedicated alarm channel which plays at maximum volume.
  ///
  /// The [alertType] field in the FCM data payload is set to 'ALARM' by
  /// the backend scheduler and by test_screen.dart so this method knows
  /// when to call itself instead of [showAmbulanceAlertNotification].
  Future<void> showAlarmNotification({
    required int navigationId,
    required String vehicleNumber,
    String? title,
    String? body,
  }) async {
    final payloadData = {
      'type': NotificationType.ambulanceAlert,
      'alert_type': 'ALARM',
      'navigation_id': navigationId.toString(),
      'vehicle_number': vehicleNumber,
      if (_currentPatientId != null) 'patient_id': _currentPatientId.toString(),
    };

    // ── CONTENT (alarm notification on receiver side): update here ────────
    const androidDetails = AndroidNotificationDetails(
      'ambulance_alarm_channel',       // uses the new alarm channel
      'Ambulance Alarm',
      channelDescription:
          'Urgent alarm for vehicles that have not yielded to an ambulance.',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,          // wakes screen even when locked
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
      // sound: RawResourceAndroidNotificationSound('alarm'), // custom alarm mp3
      actions: [
        AndroidNotificationAction(
          NotificationActionId.imAware,
          "I'm Aware",
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationActionId.movingAside,
          'Moving Aside',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );
    // ─────────────────────────────────────────────────────────────────────

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
      categoryIdentifier: 'ambulance_alert_category',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title ?? '🚨 Ambulance Alert!',
      body ?? 'URGENT: Please move aside immediately for ambulance $vehicleNumber.',
      details,
      payload: jsonEncode(payloadData),
    );

    debugPrint('[NotificationService] ALARM notification shown for nav $navigationId');
  }

  /// Save FCM token to backend for a specific patient.
  Future<bool> saveTokenToBackend(int patientId) async {
    if (_fcmToken == null) return false;

    try {
      final response = await _apiClient.patch(
        '/patient/$patientId/fcm-token',
        body: {'fcm_token': _fcmToken},
      );

      if (response is Map && response.containsKey('error')) {
        debugPrint('Failed to save FCM token: ${response['error']}');
        return false;
      }

      debugPrint('FCM token saved successfully for patient $patientId');
      return true;
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
      return false;
    }
  }

  /// Handle foreground messages - show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.notification?.title}');
    debugPrint('Message data: ${message.data}');

    // Check if this is an ambulance alert
    if (_isAmbulanceAlert(message)) {
      final alertData = _parseAmbulanceAlertData(message);
      if (alertData != null) {
        debugPrint('Ambulance alert received: ${alertData.vehicleNumber}');

        // NEW: if the backend flagged this as ALARM, show the loud alarm
        // notification instead of the standard one.
        final alertType = message.data['alert_type'];
        if (alertType == 'ALARM') {
          await showAlarmNotification(
            navigationId: alertData.navigationId,
            vehicleNumber: alertData.vehicleNumber,
          );
          return;
        }

        // Trigger ambulance alert callback instead of generic notification
        _onAmbulanceAlertReceived?.call(
          message.notification?.title ?? 'Ambulance Approaching!',
          message.notification?.body ?? 'Please clear the way.',
          alertData,
        );
        return;
      }
    }

    // Show local notification for non-ambulance foreground messages
    _showLocalNotification(message);

    // Also trigger generic callback if set
    if (message.notification != null) {
      _onNotificationReceived?.call(
        message.notification!.title ?? '',
        message.notification!.body ?? '',
        message.data,
      );
    }
  }

  /// Handle notification tap - navigate to appropriate screen.
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');

    // Check if this is an ambulance alert tap
    if (_isAmbulanceAlert(message)) {
      final alertData = _parseAmbulanceAlertData(message);
      if (alertData != null) {
        debugPrint('Ambulance alert tapped: ${alertData.vehicleNumber}');
        _onAmbulanceAlertReceived?.call(
          message.notification?.title ?? 'Ambulance Approaching!',
          message.notification?.body ?? 'Please clear the way.',
          alertData,
        );
        return;
      }
    }

    _onNotificationTap?.call(message.data);
  }

  // Callbacks for UI integration
  void Function(String title, String body, Map<String, dynamic> data)?
      _onNotificationReceived;
  void Function(Map<String, dynamic> data)? _onNotificationTap;
  void Function(String title, String body, AmbulanceAlertData data)?
      _onAmbulanceAlertReceived;
  void Function(String actionId)? _onAcknowledgmentFromNotification;

  /// Set callback for when a notification is received in foreground.
  void setOnNotificationReceived(
    void Function(String title, String body, Map<String, dynamic> data)?
        callback,
  ) {
    _onNotificationReceived = callback;
  }

  /// Set callback for when a notification is tapped.
  void setOnNotificationTap(void Function(Map<String, dynamic> data)? callback) {
    _onNotificationTap = callback;
  }

  /// Set callback for when an ambulance alert is received.
  /// This is called for AMBULANCE_ALERT type notifications.
  void setOnAmbulanceAlertReceived(
    void Function(String title, String body, AmbulanceAlertData data)? callback,
  ) {
    _onAmbulanceAlertReceived = callback;
  }

  /// Set callback for when user acknowledges via notification action button.
  /// The actionId will be either 'IM_AWARE_ACTION' or 'MOVING_ASIDE_ACTION'.
  void setOnAcknowledgmentFromNotification(
    void Function(String actionId)? callback,
  ) {
    _onAcknowledgmentFromNotification = callback;
  }

  /// Subscribe to a topic for receiving broadcast notifications.
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  /// Get current patient ID (for acknowledgments)
  int? get currentPatientId => _currentPatientId;
}

/// Data class for ambulance alert notification data
class AmbulanceAlertData {
  final int navigationId;
  final String vehicleNumber;
  final bool requireAcknowledgment;
  final String? clickAction;

  AmbulanceAlertData({
    required this.navigationId,
    required this.vehicleNumber,
    this.requireAcknowledgment = false,
    this.clickAction,
  });

  @override
  String toString() {
    return 'AmbulanceAlertData(navigationId: $navigationId, vehicleNumber: $vehicleNumber, requireAcknowledgment: $requireAcknowledgment)';
  }
}