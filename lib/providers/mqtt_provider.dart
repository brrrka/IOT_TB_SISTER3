import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/sensor_reading.dart';

class MqttProvider extends ChangeNotifier {
  // HiveMQ Cloud Configuration (from your code)
  static const String broker =
      '5edb3de92c0146109943215ae8b75a8c.s1.eu.hivemq.cloud';
  static const int port = 8883;
  static const String username = 'berka';
  static const String password = 'Berka123';
  static const String topic = 'sensor/environment';

  MqttServerClient? _client;
  bool _isConnected = false;
  List<SensorReading> _realtimeReadings = [];
  Map<String, int> _deviceMessageCounts = {};
  Map<String, SensorReading> _latestDeviceReadings = {};

  StreamController<SensorReading> _readingController =
      StreamController<SensorReading>.broadcast();

  // Getters
  bool get isConnected => _isConnected;
  List<SensorReading> get realtimeReadings =>
      List.unmodifiable(_realtimeReadings);
  Map<String, SensorReading> get latestDeviceReadings =>
      Map.unmodifiable(_latestDeviceReadings);
  Stream<SensorReading> get readingStream => _readingController.stream;
  int get totalMessages =>
      _deviceMessageCounts.values.fold(0, (sum, count) => sum + count);
  int get activeDevices => _latestDeviceReadings.length;

  Future<void> connect() async {
    try {
      print('🔌 Connecting to MQTT broker...');

      // Create client with unique ID
      final clientId =
          'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
      _client = MqttServerClient.withPort(broker, clientId, port);

      // Configure client
      _client!.logging(on: true);
      _client!.setProtocolV311();
      _client!.keepAlivePeriod = 60;
      _client!.connectTimeoutPeriod = 5000;
      _client!.autoReconnect = true;

      // Set up SSL/TLS
      _client!.secure = true;
      _client!.securityContext = SecurityContext.defaultContext;

      // Connection message
      final connMessage = MqttConnectMessage()
          .authenticateAs(username, password)
          .withClientIdentifier(clientId)
          .withWillTopic('clients/$clientId/status')
          .withWillMessage('disconnected')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      _client!.connectionMessage = connMessage;

      // Set up callbacks
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.onAutoReconnect = _onAutoReconnect;

      // Connect
      await _client!.connect();
    } catch (e) {
      print('❌ MQTT Connection failed: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  void _onConnected() {
    print('✅ MQTT Connected to $broker');
    _isConnected = true;

    // Subscribe to sensor topic
    _client!.subscribe(topic, MqttQos.atLeastOnce);

    // Set up message listener
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (var message in messages) {
        _handleMessage(message);
      }
    });

    notifyListeners();
  }

  void _onDisconnected() {
    print('⚠️ MQTT Disconnected');
    _isConnected = false;
    notifyListeners();
  }

  void _onSubscribed(String topic) {
    print('📡 Subscribed to topic: $topic');
  }

  void _onAutoReconnect() {
    print('🔄 MQTT Auto-reconnecting...');
  }

  void _handleMessage(MqttReceivedMessage<MqttMessage> message) {
    try {
      final payload = MqttPublishPayload.bytesToStringAsString(
        (message.payload as MqttPublishMessage).payload.message,
      );

      final data = json.decode(payload);
      final reading = SensorReading.fromJson(data);

      // Update statistics
      _deviceMessageCounts[reading.deviceId] =
          (_deviceMessageCounts[reading.deviceId] ?? 0) + 1;

      // Store latest reading per device
      _latestDeviceReadings[reading.deviceId] = reading;

      // Add to realtime list (keep last 100)
      _realtimeReadings.insert(0, reading);
      if (_realtimeReadings.length > 100) {
        _realtimeReadings.removeLast();
      }

      // Emit to stream
      _readingController.add(reading);

      print(
          '📊 [${reading.deviceId}] T:${reading.temperature}°C H:${reading.humidity}% (${reading.source})');

      notifyListeners();
    } catch (e) {
      print('❌ Error parsing MQTT message: $e');
    }
  }

  void disconnect() {
    if (_client != null) {
      _client!.disconnect();
      _isConnected = false;
      notifyListeners();
    }
  }

  // Get readings for specific device
  List<SensorReading> getDeviceReadings(String deviceId) {
    return _realtimeReadings
        .where((reading) => reading.deviceId == deviceId)
        .toList();
  }

  // Get recent anomalies
  List<SensorReading> getRecentAnomalies() {
    return _realtimeReadings
        .where((reading) => reading.anomaly)
        .take(20)
        .toList();
  }

  // Clear realtime data
  void clearRealtimeData() {
    _realtimeReadings.clear();
    _deviceMessageCounts.clear();
    _latestDeviceReadings.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _readingController.close();
    super.dispose();
  }
}
