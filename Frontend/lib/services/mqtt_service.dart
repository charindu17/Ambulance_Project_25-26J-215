import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Singleton MQTT service for real-time ambulance location tracking.
/// Connects to public test.mosquitto.org broker (suitable for university project).
class MqttService {
  static const String _broker = 'test.mosquitto.org';
  static const int _port = 1883;
  static const int _keepAlivePeriod = 20;

  MqttServerClient? _client;
  bool _isConnected = false;
  final _connectionController = StreamController<bool>.broadcast();

  // Singleton
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  bool get isConnected => _isConnected;
  Stream<bool> get connectionStream => _connectionController.stream;

  Future<bool> connect() async {
    if (_isConnected && _client != null) return true;

    final clientId = 'flutter_ambulance_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient(_broker, clientId);
    _client!.port = _port;
    _client!.keepAlivePeriod = _keepAlivePeriod;
    _client!.setProtocolV311();
    _client!.logging(on: false);
    _client!.autoReconnect = true;
    _client!.resubscribeOnAutoReconnect = true;

    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onAutoReconnect = _onAutoReconnect;
    _client!.onAutoReconnected = _onAutoReconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
      return _client!.connectionStatus!.state == MqttConnectionState.connected;
    } on NoConnectionException catch (_) {
      _client?.disconnect();
      return false;
    } on SocketException catch (_) {
      _client?.disconnect();
      return false;
    } catch (_) {
      _client?.disconnect();
      return false;
    }
  }

  void _onConnected() {
    _isConnected = true;
    _connectionController.add(true);
  }

  void _onDisconnected() {
    _isConnected = false;
    _connectionController.add(false);
  }

  void _onAutoReconnect() {
    _isConnected = false;
    _connectionController.add(false);
  }

  void _onAutoReconnected() {
    _isConnected = true;
    _connectionController.add(true);
  }

  /// Publish a message to the specified topic.
  void publish(String topic, String message) {
    if (!_isConnected || _client == null) return;

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  /// Subscribe to a topic and return a stream of messages.
  Stream<String> subscribe(String topic) {
    if (!_isConnected || _client == null) {
      return const Stream.empty();
    }

    _client!.subscribe(topic, MqttQos.atMostOnce);

    return _client!.updates!
        .where((messages) => messages.isNotEmpty && messages[0].topic == topic)
        .map((messages) {
      final recMess = messages[0].payload as MqttPublishMessage;
      return MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    });
  }

  /// Unsubscribe from a topic.
  void unsubscribe(String topic) {
    _client?.unsubscribe(topic);
  }

  /// Disconnect from the MQTT broker.
  void disconnect() {
    _client?.disconnect();
    _isConnected = false;
  }

  /// Dispose the service and clean up resources.
  void dispose() {
    disconnect();
    _connectionController.close();
  }
}
