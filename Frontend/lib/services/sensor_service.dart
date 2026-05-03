import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'api_client.dart';

/// Holds the 7 computed feature values that the Random Forest model expects.
class SensorFeatureWindow {
  final double avgSpeed;
  final double maxForce;
  final double stdForce;
  final double minForce;
  final double avgJerk;
  final double avgLateral;
  final double maxLateral;

  SensorFeatureWindow({
    required this.avgSpeed,
    required this.maxForce,
    required this.stdForce,
    required this.minForce,
    required this.avgJerk,
    required this.avgLateral,
    required this.maxLateral,
  });

  Map<String, dynamic> toJson() => {
        'avg_speed': avgSpeed,
        'max_force': maxForce,
        'std_force': stdForce,
        'min_force': minForce,
        'avg_jerk': avgJerk,
        'avg_lateral': avgLateral,
        'max_lateral': maxLateral,
      };
}

/// Result returned after asking the backend model to predict behaviour.
class PredictionResult {
  final String prediction; // e.g. "Cruising", "Braking", "Lane Left", "Lane Right"
  final double confidence; // 0.0 – 1.0
  final Map<String, double> probabilities;

  PredictionResult({
    required this.prediction,
    required this.confidence,
    required this.probabilities,
  });

  /// Returns true when the vehicle is still moving forward without yielding.
  /// Used by the alarm-notification logic to decide who gets the alarm.
  bool get isNotYielding =>
      prediction == 'Cruising' && confidence > 0.60;
}

/// Collects raw accelerometer + GPS readings over a sliding window,
/// computes the 7 engineered features, and asks the backend to predict
/// the current driving behaviour.
///
/// Usage:
///   final svc = SensorService();
///   await svc.startListening();
///   final result = await svc.predictCurrentBehaviour();
///   svc.stopListening();
class SensorService {
  // ── tuneable constants ──────────────────────────────────────────────────
  static const Duration _windowDuration = Duration(seconds: 5);

  // ── raw sample buffers filled by platform sensor streams ───────────────
  final List<double> _forceSamples = []; // |acceleration| magnitude (m/s²)
  final List<double> _lateralSamples = []; // |Y-axis accel| ≈ lateral force
  double _lastSpeed = 0.0; // m/s from GPS
  double _lastForce = 0.0; // previous magnitude for jerk calculation
  final List<double> _jerkSamples = [];

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<Position>? _gpsSub;
  bool _isListening = false;

  final ApiClient _client;

  SensorService({ApiClient? client}) : _client = client ?? ApiClient();

  bool get isListening => _isListening;

  // ── lifecycle ───────────────────────────────────────────────────────────

  /// Start collecting accelerometer and GPS data.
  /// Call once when the navigation/ride begins.
  Future<void> startListening() async {
    if (_isListening) return;

    // --- GPS stream ---
    final hasPermission = await _requestLocationPermission();
    if (hasPermission) {
      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position pos) {
        _lastSpeed = pos.speed.clamp(0.0, double.infinity);
      });
    }

    // --- Accelerometer stream ---
    // sensors_plus: accelerometerEventStream() emits raw m/s² values.
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent e) {
      // Longitudinal magnitude (forward/backward + vertical lumped together)
      final force = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      final lateral = e.x.abs(); // left/right axis

      _forceSamples.add(force);
      _lateralSamples.add(lateral);

      // Jerk = |Δforce| between consecutive samples
      final jerk = (_lastForce - force).abs();
      _jerkSamples.add(jerk);
      _lastForce = force;

      // Keep buffers bounded to the last ~windowDuration worth of samples
      // Assuming ~50 Hz accelerometer → 250 samples per 5 s window
      const maxSamples = 300;
      if (_forceSamples.length > maxSamples) {
        _forceSamples.removeAt(0);
        _lateralSamples.removeAt(0);
        _jerkSamples.removeAt(0);
      }
    });

    _isListening = true;
    debugPrint('[SensorService] Started listening to sensors.');
  }

  /// Stop collecting sensor data and release resources.
  void stopListening() {
    _accelSub?.cancel();
    _accelSub = null;
    _gpsSub?.cancel();
    _gpsSub = null;
    _isListening = false;
    _forceSamples.clear();
    _lateralSamples.clear();
    _jerkSamples.clear();
    debugPrint('[SensorService] Stopped listening to sensors.');
  }

  // ── feature engineering ─────────────────────────────────────────────────

  /// Compute the 7-feature window from the currently buffered samples.
  /// Returns null if there are not enough samples yet.
  SensorFeatureWindow? _computeFeatures() {
    if (_forceSamples.length < 10) {
      debugPrint('[SensorService] Not enough samples to compute features.');
      return null;
    }

    final avgForce = _mean(_forceSamples);
    final maxForce = _forceSamples.reduce(max);
    final minForce = _forceSamples.reduce(min);
    final stdForce = _std(_forceSamples, avgForce);
    final avgJerk = _mean(_jerkSamples);
    final avgLateral = _mean(_lateralSamples);
    final maxLateral = _lateralSamples.reduce(max);

    return SensorFeatureWindow(
      avgSpeed: _lastSpeed,
      maxForce: maxForce,
      stdForce: stdForce,
      minForce: minForce,
      avgJerk: avgJerk,
      avgLateral: avgLateral,
      maxLateral: maxLateral,
    );
  }

  // ── prediction ──────────────────────────────────────────────────────────

  /// Compute features from the current sensor window and ask the backend
  /// Random Forest model to predict the driving behaviour.
  ///
  /// Returns null if sensors have not collected enough data yet.
  Future<PredictionResult?> predictCurrentBehaviour() async {
    final features = _computeFeatures();
    if (features == null) return null;

    try {
      debugPrint('[SensorService] Sending features to /prediction/predict: '
          '${features.toJson()}');

      final response = await _client.post(
        '/prediction/predict',
        body: features.toJson(),
      );

      if (response is Map && response.containsKey('error')) {
        debugPrint('[SensorService] Prediction error: ${response['error']}');
        return null;
      }

      final probsRaw =
          (response['probabilities'] as Map<String, dynamic>?) ?? {};
      final probs = probsRaw
          .map((k, v) => MapEntry(k, (v as num).toDouble()));

      return PredictionResult(
        prediction: response['prediction'] as String? ?? 'Cruising',
        confidence: (response['confidence'] as num?)?.toDouble() ?? 0.0,
        probabilities: probs,
      );
    } catch (e) {
      debugPrint('[SensorService] Exception calling prediction API: $e');
      return null;
    }
  }

  // ── helpers ─────────────────────────────────────────────────────────────

  double _mean(List<double> values) =>
      values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;

  double _std(List<double> values, double mean) {
    if (values.length < 2) return 0.0;
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length;
    return sqrt(variance);
  }

  Future<bool> _requestLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm != LocationPermission.denied &&
        perm != LocationPermission.deniedForever;
  }
}
