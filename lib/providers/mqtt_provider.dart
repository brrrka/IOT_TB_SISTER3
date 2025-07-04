import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/sensor_reading.dart';

// Enhanced model untuk sensor_001
class EnhancedSensorReading {
  final String deviceId;
  final double temperature;
  final double humidity;
  final int timestamp;
  final String source;
  final int msgCount;
  final bool anomaly;

  // PIR sensor data
  final bool? motionDetected;
  final int? lastTrigger;
  final int? triggerCount;
  final int? timeSinceTrigger;

  // Rain sensor data
  final int? rainAnalogValue;
  final bool? rainDigitalState;
  final bool? isRaining;
  final String? rainIntensity;
  final int? rainLevelPercent;

  // System info
  final int? freeHeap;
  final int? wifiRssi;
  final int? uptimeMs;

  EnhancedSensorReading({
    required this.deviceId,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
    required this.source,
    required this.msgCount,
    required this.anomaly,
    this.motionDetected,
    this.lastTrigger,
    this.triggerCount,
    this.timeSinceTrigger,
    this.rainAnalogValue,
    this.rainDigitalState,
    this.isRaining,
    this.rainIntensity,
    this.rainLevelPercent,
    this.freeHeap,
    this.wifiRssi,
    this.uptimeMs,
  });

  bool get isEnhanced => motionDetected != null || isRaining != null;

  String get displayTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
          .toString()
          .substring(11, 19);

  String get motionStatus => motionDetected == true ? 'MOTION' : 'STILL';

  String get rainStatus {
    if (rainIntensity == null) return 'Unknown';
    switch (rainIntensity) {
      case 'none':
        return 'No Rain ☀️';
      case 'light':
        return 'Light Rain 🌦️';
      case 'moderate':
        return 'Moderate Rain 🌧️';
      case 'heavy':
        return 'Heavy Rain ⛈️';
      default:
        return 'Unknown';
    }
  }

  factory EnhancedSensorReading.fromJson(Map<String, dynamic> json) {
    final pirData = json['pir_sensor'] as Map<String, dynamic>?;
    final rainData = json['rain_sensor'] as Map<String, dynamic>?;
    final systemData = json['system_info'] as Map<String, dynamic>?;

    return EnhancedSensorReading(
      deviceId: json['device_id'] ?? '',
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] ?? 0,
      source: json['source'] ?? '',
      msgCount: json['msg_count'] ?? 0,
      anomaly: json['anomaly'] ?? false,
      motionDetected: pirData?['motion_detected'],
      lastTrigger: pirData?['last_trigger'],
      triggerCount: pirData?['trigger_count'],
      timeSinceTrigger: pirData?['time_since_trigger'],
      rainAnalogValue: rainData?['analog_value'],
      rainDigitalState: rainData?['digital_state'],
      isRaining: rainData?['is_raining'],
      rainIntensity: rainData?['intensity'],
      rainLevelPercent: rainData?['rain_level_percent'],
      freeHeap: systemData?['free_heap'],
      wifiRssi: systemData?['wifi_rssi'],
      uptimeMs: systemData?['uptime_ms'],
    );
  }
}

class MqttProvider extends ChangeNotifier {
  static const String broker =
      '5edb3de92c0146109943215ae8b75a8c.s1.eu.hivemq.cloud';
  static const int port = 8883;
  static const String username = 'berka';
  static const String password = 'Berka123';
  static const String topic = 'sensor/environment';

  MqttServerClient? _client;
  bool _isConnected = false;

  // Standard sensor readings
  List<SensorReading> _realtimeReadings = [];
  Map<String, int> _deviceMessageCounts = {};
  Map<String, SensorReading> _latestDeviceReadings = {};

  // Enhanced sensor_001 readings
  List<EnhancedSensorReading> _enhancedReadings = [];
  EnhancedSensorReading? _latestEnhancedReading;
  int _totalPirTriggers = 0;
  int _totalRainDetections = 0;
  int _enhancedMessageCount = 0;

  StreamController<SensorReading> _readingController =
      StreamController<SensorReading>.broadcast();
  StreamController<EnhancedSensorReading> _enhancedController =
      StreamController<EnhancedSensorReading>.broadcast();

  // Getters
  bool get isConnected => _isConnected;
  List<SensorReading> get realtimeReadings =>
      List.unmodifiable(_realtimeReadings);
  Map<String, SensorReading> get latestDeviceReadings =>
      Map.unmodifiable(_latestDeviceReadings);
  List<EnhancedSensorReading> get enhancedReadings =>
      List.unmodifiable(_enhancedReadings);
  EnhancedSensorReading? get latestEnhancedReading => _latestEnhancedReading;
  int get totalPirTriggers => _totalPirTriggers;
  int get totalRainDetections => _totalRainDetections;
  int get enhancedMessageCount => _enhancedMessageCount;
  Stream<SensorReading> get readingStream => _readingController.stream;
  Stream<EnhancedSensorReading> get enhancedStream =>
      _enhancedController.stream;
  int get totalMessages =>
      _deviceMessageCounts.values.fold(0, (sum, count) => sum + count) +
      _enhancedMessageCount;
  int get activeDevices =>
      _latestDeviceReadings.length + (_latestEnhancedReading != null ? 1 : 0);

  Future<void> connect() async {
    try {
      print('🔌 Connecting to MQTT broker...');

      final clientId =
          'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
      _client = MqttServerClient.withPort(broker, clientId, port);

      _client!.logging(on: true);
      _client!.setProtocolV311();
      _client!.keepAlivePeriod = 60;
      _client!.connectTimeoutPeriod = 5000;
      _client!.autoReconnect = true;

      _client!.secure = true;
      _client!.securityContext = SecurityContext.defaultContext;

      final connMessage = MqttConnectMessage()
          .authenticateAs(username, password)
          .withClientIdentifier(clientId)
          .withWillTopic('clients/$clientId/status')
          .withWillMessage('disconnected')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      _client!.connectionMessage = connMessage;

      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.onAutoReconnect = _onAutoReconnect;

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

    _client!.subscribe(topic, MqttQos.atLeastOnce);

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
      final deviceId = data['device_id'] ?? '';

      if (deviceId == 'sensor_001') {
        if (data.containsKey('pir_sensor') || data.containsKey('rain_sensor')) {
          _handleSensor001Enhanced(data);
        } else {
          _handleStandardSensor(data);
        }
      } else {
        _handleStandardSensor(data);
      }
    } catch (e) {
      print('❌ Error parsing MQTT message: $e');
    }
  }

  void _handleSensor001Enhanced(Map<String, dynamic> data) {
    try {
      final enhancedReading = EnhancedSensorReading.fromJson(data);

      _enhancedReadings.insert(0, enhancedReading);
      if (_enhancedReadings.length > 50) {
        _enhancedReadings.removeLast();
      }

      _latestEnhancedReading = enhancedReading;
      _enhancedMessageCount++;

      if (enhancedReading.motionDetected == true) {
        _totalPirTriggers++;
        print('🚶 [sensor_001] Motion detected! Total: $_totalPirTriggers');
      }

      if (enhancedReading.isRaining == true) {
        _totalRainDetections++;
        print(
            '🌧️ [sensor_001] Rain detected! Intensity: ${enhancedReading.rainIntensity}');
      }

      _enhancedController.add(enhancedReading);

      print(
          '⚡ [sensor_001] T:${enhancedReading.temperature}°C H:${enhancedReading.humidity}% '
          'PIR:${enhancedReading.motionStatus} Rain:${enhancedReading.rainStatus}');

      notifyListeners();
    } catch (e) {
      print('❌ Error handling enhanced sensor_001: $e');
    }
  }

  void _handleStandardSensor(Map<String, dynamic> data) {
    try {
      final reading = SensorReading.fromJson(data);

      _deviceMessageCounts[reading.deviceId] =
          (_deviceMessageCounts[reading.deviceId] ?? 0) + 1;
      _latestDeviceReadings[reading.deviceId] = reading;

      _realtimeReadings.insert(0, reading);
      if (_realtimeReadings.length > 100) {
        _realtimeReadings.removeLast();
      }

      _readingController.add(reading);

      print(
          '📊 [${reading.deviceId}] T:${reading.temperature}°C H:${reading.humidity}%');

      notifyListeners();
    } catch (e) {
      print('❌ Error handling standard sensor: $e');
    }
  }

  void disconnect() {
    if (_client != null) {
      _client!.disconnect();
      _isConnected = false;
      notifyListeners();
    }
  }

  List<EnhancedSensorReading> getEnhancedReadings(
      {int? limit, bool? motionOnly, bool? rainOnly}) {
    var filtered = _enhancedReadings.where((reading) {
      if (motionOnly == true && reading.motionDetected != true) return false;
      if (rainOnly == true && reading.isRaining != true) return false;
      return true;
    }).toList();

    if (limit != null && limit > 0) {
      return filtered.take(limit).toList();
    }

    return filtered;
  }

  Map<String, dynamic> getPirStatistics() {
    if (_latestEnhancedReading == null) return {};

    return {
      'total_triggers': _totalPirTriggers,
      'current_motion': _latestEnhancedReading!.motionDetected,
      'last_trigger_time': _latestEnhancedReading!.lastTrigger,
      'time_since_trigger': _latestEnhancedReading!.timeSinceTrigger,
    };
  }

  Map<String, dynamic> getRainStatistics() {
    if (_latestEnhancedReading == null) return {};

    return {
      'total_detections': _totalRainDetections,
      'current_raining': _latestEnhancedReading!.isRaining,
      'current_intensity': _latestEnhancedReading!.rainIntensity,
      'analog_value': _latestEnhancedReading!.rainAnalogValue,
      'rain_level_percent': _latestEnhancedReading!.rainLevelPercent,
    };
  }

  Map<String, dynamic> getSystemInfo() {
    if (_latestEnhancedReading == null) return {};

    return {
      'free_heap': _latestEnhancedReading!.freeHeap,
      'wifi_rssi': _latestEnhancedReading!.wifiRssi,
      'uptime_ms': _latestEnhancedReading!.uptimeMs,
      'uptime_hours': _latestEnhancedReading!.uptimeMs != null
          ? (_latestEnhancedReading!.uptimeMs! / (1000 * 60 * 60))
              .toStringAsFixed(1)
          : null,
    };
  }

  List<SensorReading> getDeviceReadings(String deviceId) {
    return _realtimeReadings
        .where((reading) => reading.deviceId == deviceId)
        .toList();
  }

  List<SensorReading> getRecentAnomalies() {
    return _realtimeReadings
        .where((reading) => reading.anomaly)
        .take(20)
        .toList();
  }

  void clearRealtimeData() {
    _realtimeReadings.clear();
    _deviceMessageCounts.clear();
    _latestDeviceReadings.clear();
    _enhancedReadings.clear();
    _latestEnhancedReading = null;
    _totalPirTriggers = 0;
    _totalRainDetections = 0;
    _enhancedMessageCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _readingController.close();
    _enhancedController.close();
    super.dispose();
  }
}
