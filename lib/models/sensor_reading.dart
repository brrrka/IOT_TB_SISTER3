// Tambahkan ini ke file sensor_reading.dart sebagai alternatif factory method
// yang lebih aman untuk parsing JSON

import 'package:json_annotation/json_annotation.dart';

part 'sensor_reading.g.dart';

@JsonSerializable()
class SensorReading {
  @JsonKey(name: 'device_id')
  final String deviceId;

  final int timestamp;
  final double temperature;
  final double humidity;
  final String source;

  @JsonKey(name: 'msg_count')
  final int msgCount;

  final bool anomaly;

  @JsonKey(name: 'formatted_time')
  final String? formattedTime;

  @JsonKey(name: 'batch_id')
  final String? batchId;

  @JsonKey(name: 'is_processed_anomaly')
  final bool? isProcessedAnomaly;

  @JsonKey(name: 'anomaly_types')
  final List<String>? anomalyTypes;

  SensorReading({
    required this.deviceId,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.source,
    required this.msgCount,
    required this.anomaly,
    this.formattedTime,
    this.batchId,
    this.isProcessedAnomaly,
    this.anomalyTypes,
  });

  // ORIGINAL generated method (bisa error)
  factory SensorReading.fromJson(Map<String, dynamic> json) =>
      _$SensorReadingFromJson(json);

  // SAFE alternative method - gunakan ini untuk API calls
  factory SensorReading.fromJsonSafe(Map<String, dynamic> json) {
    try {
      return SensorReading(
        deviceId: _parseString(json['device_id'] ?? json['deviceId'] ?? ''),
        timestamp: _parseInt(json['timestamp'] ?? 0),
        temperature: _parseDouble(json['temperature'] ?? 0.0),
        humidity: _parseDouble(json['humidity'] ?? 0.0),
        source: _parseString(json['source'] ?? 'unknown'),
        msgCount: _parseInt(json['msg_count'] ?? json['msgCount'] ?? 0),
        anomaly:
            json['anomaly'] == true || json['is_processed_anomaly'] == true,
        formattedTime: json['formatted_time']?.toString() ??
            json['formattedTime']?.toString(),
        batchId: json['batch_id']?.toString() ?? json['batchId']?.toString(),
        isProcessedAnomaly: json['is_processed_anomaly'] == true ||
            json['isProcessedAnomaly'] == true,
        anomalyTypes:
            _parseStringList(json['anomaly_types'] ?? json['anomalyTypes']),
      );
    } catch (e) {
      print('❌ Error parsing SensorReading: $e');
      print('❌ JSON data: $json');

      // Return a default SensorReading dengan data minimal
      return SensorReading(
        deviceId: json['device_id']?.toString() ??
            json['deviceId']?.toString() ??
            'unknown',
        timestamp: 0,
        temperature: 0.0,
        humidity: 0.0,
        source: 'unknown',
        msgCount: 0,
        anomaly: false,
      );
    }
  }

  Map<String, dynamic> toJson() => _$SensorReadingToJson(this);

  // Helper functions untuk parsing yang aman
  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return null;
  }

  // Utility getters (sama seperti sebelumnya)
  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  bool get isHardware =>
      source == 'hardware' ||
      ['sensor_001', 'sensor_002', 'sensor_003'].contains(deviceId);

  bool get isVirtual =>
      source == 'simulation' || (deviceId.startsWith('sensor_') && !isHardware);

  String get displayTime =>
      formattedTime ??
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';

  String get deviceType => isHardware ? 'Hardware' : 'Virtual';

  // Temperature status
  String get temperatureStatus {
    if (temperature < 5 || temperature > 50) return 'Critical';
    if (temperature < 10 || temperature > 40) return 'Warning';
    return 'Normal';
  }

  // Humidity status
  String get humidityStatus {
    if (humidity < 5 || humidity > 95) return 'Critical';
    if (humidity < 20 || humidity > 80) return 'Warning';
    return 'Normal';
  }

  // Overall status
  String get overallStatus {
    if (anomaly || isProcessedAnomaly == true) return 'Anomaly';
    if (temperatureStatus == 'Critical' || humidityStatus == 'Critical')
      return 'Critical';
    if (temperatureStatus == 'Warning' || humidityStatus == 'Warning')
      return 'Warning';
    return 'Normal';
  }

  @override
  String toString() {
    return 'SensorReading(deviceId: $deviceId, temp: ${temperature}°C, humidity: ${humidity}%, source: $source, anomaly: $anomaly)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SensorReading &&
        other.deviceId == deviceId &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => deviceId.hashCode ^ timestamp.hashCode;
}
