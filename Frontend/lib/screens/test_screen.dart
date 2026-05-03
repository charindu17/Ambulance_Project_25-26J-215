import 'package:dileesara_project/screens/auth/patient_login_screen.dart';
import 'package:flutter/material.dart';
import '../services/services.dart';
import '../services/sensor_service.dart'; // NEW: sensor + prediction service
import '../utils/navigation_mixin.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> with NavigationMixin {
  final NotificationApiService _notificationApiService =
      NotificationApiService();
  final PushNotificationSenderService _pushService =
      PushNotificationSenderService();

  // NEW: one SensorService per patient to collect their sensor window
  // In a real deployment this would live on the patient's own device;
  // here it runs on the driver's test device to simulate the behaviour.
  final SensorService _sensorService = SensorService();

  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  String? _error;
  int? _sendingToPatientId;

  // NEW: tracks the prediction result that was used for the last send,
  // so it can be shown in the UI for demonstration purposes.
  String? _lastPredictionLabel;
  double? _lastPredictionConfidence;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    // NEW: start sensor collection as soon as the screen opens so that
    // by the time the driver presses "Send Alert" there is already a
    // valid feature window ready.
    _sensorService.startListening();
  }

  @override
  void dispose() {
    _sensorService.stopListening(); // NEW: clean up sensor streams
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _notificationApiService.getAllPatients();

    if (!mounted) return;

    if (response.containsKey('error')) {
      setState(() {
        _error = response['error'].toString();
        _isLoading = false;
      });
    } else {
      final patientsList = response['patients'] as List<dynamic>? ?? [];
      setState(() {
        _patients = patientsList.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    }
  }

  /// Decides whether to send a normal alert or an ALARM alert based on
  /// the ML model prediction for this vehicle's current behaviour.
  ///
  /// Logic:
  ///   1. Ask SensorService to compute features and call /prediction/predict.
  ///   2. If the model says the vehicle is STILL CRUISING (not yielding)
  ///      with high confidence → send ALARM notification (urgent, loud).
  ///   3. Otherwise → send the regular awareness notification.
  ///   4. Always send the companion "Ambulance is near" notification.
  Future<void> _sendNotificationToPatient(Map<String, dynamic> patient) async {
    final patientId = patient['id'] as int?;
    final patientName = patient['name'] as String? ?? 'Unknown';

    if (patientId == null) {
      showErrorSnackbar(context, 'Invalid patient ID');
      return;
    }

    setState(() => _sendingToPatientId = patientId);

    // ── STEP 1: Run ML prediction on current sensor window ───────────────
    // This calls POST /prediction/predict with the 7 computed features.
    // If the sensor window is too short the result is null and we fall
    // back to the standard alert so the UX is never blocked.
    final prediction = await _sensorService.predictCurrentBehaviour();

    if (prediction != null) {
      setState(() {
        _lastPredictionLabel = prediction.prediction;
        _lastPredictionConfidence =
            (prediction.confidence * 100).roundToDouble();
      });
      debugPrint(
          '[TestScreen] Prediction for patient $patientId: '
          '${prediction.prediction} (${(prediction.confidence * 100).toStringAsFixed(1)}%)');
    }

    // ── STEP 2: Choose alert type based on prediction ────────────────────
    // isNotYielding returns true when prediction == "Cruising" AND
    // confidence > 0.60, meaning the vehicle has not slowed down or
    // moved aside → it should receive the ALARM notification.
    final bool shouldAlarm =
        prediction != null && prediction.isNotYielding;

    bool success;

    if (shouldAlarm) {
      // ── ALARM notification (vehicle has NOT yielded) ──────────────────
      // ── CONTENT: update header & body of alarm notification here ──────
      success = await _pushService.sendToPatients(
        patientIds: [patientId],
        title: 'Ambulance is Nearby ',          // ← alarm header
        body: 'Ambulance approaching! Please move aside and clear the way. '
              'Your cooperation saves lives!',   // ← alarm body
        data: {
          'type': 'AMBULANCE_ALERT',
          'alert_type': 'ALARM',                // signals alarm on receiver
          'navigation_id': '0',
          'vehicle_number': 'AMB-001',
          'require_acknowledgment': 'true',
          // prediction context sent in data payload for showcase
          'ml_prediction': prediction.prediction,
          'ml_confidence': prediction.confidence.toStringAsFixed(4),
        },
      );
      debugPrint('[TestScreen] ALARM notification sent to patient $patientId '
          '(model said: ${prediction.prediction})');
    } else {
      // ── NORMAL awareness notification (vehicle already yielding / ──────
      // ── sensor window not ready yet)  ─────────────────────────────────
      // ── CONTENT: update header & body of normal notification here ─────
      success = await _pushService.sendToPatients(
        patientIds: [patientId],
        title: 'Ambulance is Nearby ',          // ← normal header
        body: 'Ambulance approaching! Please move aside and clear the way. '
              'Your cooperation saves lives!',   // ← normal body
        data: {
          'type': 'AMBULANCE_ALERT',
          'alert_type': 'NORMAL',
          'navigation_id': '0',
          'vehicle_number': 'AMB-001',
          'require_acknowledgment': 'true',
          if (prediction != null) ...{
            'ml_prediction': prediction.prediction,
            'ml_confidence': prediction.confidence.toStringAsFixed(4),
          },
        },
      );
    }

    // ── STEP 3: Always send the companion "Ambulance is near" notification
    if (success) {
      // ── CONTENT ("Ambulance is near" notification): update header & body here ──
      await _pushService.sendToPatients(
        patientIds: [patientId],
        title: 'Nearby Vehicles Alert 🚨',
        body: 'Vehicle behind you have confirmed that an ambulance is approaching.',
      );
      // ───────────────────────────────────────────────────────────────────
    }

    if (!mounted) return;

    setState(() => _sendingToPatientId = null);

    if (success) {
      final alertKind = shouldAlarm ? '🚨 ALARM' : '🔔 Normal';
      showSuccessSnackbar(
          context, '$alertKind notification sent to $patientName');
    } else {
      showErrorSnackbar(context, 'Failed to send notification to $patientName');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notifications'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPatients),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientLoginScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      // NEW: show last ML prediction at top for demonstration / showcase
      body: Column(
        children: [
          if (_lastPredictionLabel != null)
            _buildPredictionBanner(theme),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  /// Small banner shown after the first successful prediction so the
  /// research panel can see the model output in action.
  Widget _buildPredictionBanner(ThemeData theme) {
    final isAlarm = _lastPredictionLabel == 'Cruising' &&
        (_lastPredictionConfidence ?? 0) > 60;
    return Container(
      width: double.infinity,
      color: isAlarm
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            isAlarm ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: isAlarm
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ML Prediction: $_lastPredictionLabel '
              '($_lastPredictionConfidence% confidence)'
              '${isAlarm ? ' → ALARM sent' : ' → Normal alert sent'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isAlarm
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load patients', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadPatients,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('No patients found', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'There are no registered patients yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPatients,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _patients.length,
        itemBuilder: (context, index) {
          final patient = _patients[index];
          return _buildPatientCard(patient, theme);
        },
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient, ThemeData theme) {
    final patientId = patient['id'] as int?;
    final name = patient['name'] as String? ?? 'Unknown';
    final email = patient['email'] as String? ?? '';
    final phone = patient['phone'] as String? ?? '';
    final isSending = _sendingToPatientId == patientId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email.isNotEmpty)
              Text(
                email,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (phone.isNotEmpty)
              Text(
                phone,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: isSending
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: Icon(
                  Icons.notifications_active,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Send Alert',
                onPressed: () => _sendNotificationToPatient(patient),
              ),
        onTap: isSending ? null : () => _sendNotificationToPatient(patient),
      ),
    );
  }
}