import 'package:flutter/material.dart';

class DeviceStats {
  final String deviceId;
  final int readingCount;
  final double avgTemperature;
  final double avgHumidity;
  final double minTemperature;
  final double maxTemperature;
  final double minHumidity;
  final double maxHumidity;
  final int lastReadingTime;
  final String source;

  // ADDED: Support for anomaly data from new API structure
  final int normalCount;
  final int anomalyCount;

  DeviceStats({
    required this.deviceId,
    required this.readingCount,
    required this.avgTemperature,
    required this.avgHumidity,
    required this.minTemperature,
    required this.maxTemperature,
    required this.minHumidity,
    required this.maxHumidity,
    required this.lastReadingTime,
    required this.source,
    this.normalCount = 0, // ADDED: Default to 0 for backward compatibility
    this.anomalyCount = 0, // ADDED: Default to 0 for backward compatibility
  });

  factory DeviceStats.fromJson(Map<String, dynamic> json) {
    try {
      return DeviceStats(
        deviceId: _parseString(json['device_id'] ?? json['deviceId']),
        readingCount: _parseInt(json['reading_count'] ?? json['readingCount']),
        avgTemperature:
            _parseDouble(json['avg_temperature'] ?? json['avgTemperature']),
        avgHumidity: _parseDouble(json['avg_humidity'] ?? json['avgHumidity']),
        minTemperature:
            _parseDouble(json['min_temperature'] ?? json['minTemperature']),
        maxTemperature:
            _parseDouble(json['max_temperature'] ?? json['maxTemperature']),
        minHumidity: _parseDouble(json['min_humidity'] ?? json['minHumidity']),
        maxHumidity: _parseDouble(json['max_humidity'] ?? json['maxHumidity']),
        lastReadingTime:
            _parseInt(json['last_reading_time'] ?? json['lastReadingTime']),
        source: _parseString(json['source'], defaultValue: 'unknown'),
        // ADDED: Support for anomaly data from fixed API
        normalCount: _parseInt(json['normal_count'] ?? json['normalCount']),
        anomalyCount: _parseInt(json['anomaly_count'] ?? json['anomalyCount']),
      );
    } catch (e) {
      print('❌ Error parsing DeviceStats: $e');
      print('❌ JSON data: $json');

      // FIXED: Return default DeviceStats instead of rethrowing
      return DeviceStats(
        deviceId: json['device_id']?.toString() ??
            json['deviceId']?.toString() ??
            'unknown',
        readingCount: 0,
        avgTemperature: 0.0,
        avgHumidity: 0.0,
        minTemperature: 0.0,
        maxTemperature: 0.0,
        minHumidity: 0.0,
        maxHumidity: 0.0,
        lastReadingTime: 0,
        source: 'unknown',
        normalCount: 0,
        anomalyCount: 0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'reading_count': readingCount,
      'avg_temperature': avgTemperature,
      'avg_humidity': avgHumidity,
      'min_temperature': minTemperature,
      'max_temperature': maxTemperature,
      'min_humidity': minHumidity,
      'max_humidity': maxHumidity,
      'last_reading_time': lastReadingTime,
      'source': source,
      'normal_count': normalCount, // ADDED
      'anomaly_count': anomalyCount, // ADDED
    };
  }

  // Helper functions untuk parsing yang aman
  static String _parseString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
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

  DateTime get lastReadingDateTime =>
      DateTime.fromMillisecondsSinceEpoch(lastReadingTime * 1000);

  // ADDED: New convenience getters that work with existing model
  bool get isHardware => source.toLowerCase() == 'hardware';
  bool get isVirtual => source.toLowerCase() == 'simulation';

  // ADDED: Calculate anomaly percentage
  double get anomalyPercentage {
    if (readingCount == 0) return 0.0;
    return (anomalyCount / readingCount) * 100;
  }

  // ADDED: Status description based on anomalies and last reading time
  String get statusDescription {
    if (readingCount == 0) return 'No data';

    final now = DateTime.now();
    final lastReading = lastReadingDateTime;
    final minutesAgo = now.difference(lastReading).inMinutes;

    if (minutesAgo > 10) return 'Offline';
    if (anomalyCount > 0) return 'Anomalies detected';
    return 'Normal';
  }

  // ADDED: Status color
  Color get statusColor {
    final status = statusDescription;
    switch (status) {
      case 'Normal':
        return Colors.green;
      case 'Anomalies detected':
        return Colors.orange;
      case 'Offline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ADDED: Display time since last reading
  String get lastReadingDisplay {
    final now = DateTime.now();
    final lastReading = lastReadingDateTime;
    final difference = now.difference(lastReading);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // ADDED: Source display name
  String get sourceDisplay {
    switch (source.toLowerCase()) {
      case 'hardware':
        return 'Hardware';
      case 'simulation':
        return 'Virtual';
      default:
        return source;
    }
  }
}
