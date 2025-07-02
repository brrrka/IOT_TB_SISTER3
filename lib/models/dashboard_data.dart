import 'sensor_reading.dart';
import 'device_stats.dart';

class DashboardData {
  final String status;
  final String? lastUpdate;
  final String lastChecked;
  final String dataFreshness;
  final DashboardSummary? summary;
  final List<SensorReading>? recentReadings;
  final List<DeviceStats>? topDevices;
  final List<SensorReading>? recentAnomalies;

  DashboardData({
    required this.status,
    this.lastUpdate,
    required this.lastChecked,
    required this.dataFreshness,
    this.summary,
    this.recentReadings,
    this.topDevices,
    this.recentAnomalies,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    try {
      return DashboardData(
        status: json['status']?.toString() ?? 'unknown',
        lastUpdate: json['last_update']?.toString(),
        lastChecked: json['last_checked']?.toString() ?? '',
        dataFreshness: json['data_freshness']?.toString() ?? '',
        summary: json['summary'] != null
            ? DashboardSummary.fromJson(
                Map<String, dynamic>.from(json['summary']))
            : null,
        recentReadings: json['recent_readings'] != null
            ? (json['recent_readings'] as List)
                .map(
                    (x) => SensorReading.fromJson(Map<String, dynamic>.from(x)))
                .toList()
            : null,
        topDevices: json['top_devices'] != null
            ? (json['top_devices'] as List)
                .map((x) => DeviceStats.fromJson(Map<String, dynamic>.from(x)))
                .toList()
            : null,
        recentAnomalies: json['recent_anomalies'] != null
            ? (json['recent_anomalies'] as List)
                .map(
                    (x) => SensorReading.fromJson(Map<String, dynamic>.from(x)))
                .toList()
            : null,
      );
    } catch (e) {
      print('❌ Error parsing DashboardData: $e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'last_update': lastUpdate,
      'last_checked': lastChecked,
      'data_freshness': dataFreshness,
      'summary': summary?.toJson(),
      'recent_readings': recentReadings?.map((x) => x.toJson()).toList(),
      'top_devices': topDevices?.map((x) => x.toJson()).toList(),
      'recent_anomalies': recentAnomalies?.map((x) => x.toJson()).toList(),
    };
  }
}

class DashboardSummary {
  final int totalDevices;
  final int recentReadings;
  final int anomalyCount;
  final double avgTemperature;
  final double avgHumidity;

  DashboardSummary({
    required this.totalDevices,
    required this.recentReadings,
    required this.anomalyCount,
    required this.avgTemperature,
    required this.avgHumidity,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    try {
      return DashboardSummary(
        totalDevices: _parseInt(json['total_devices'] ?? json['totalDevices']),
        recentReadings:
            _parseInt(json['recent_readings'] ?? json['recentReadings']),
        anomalyCount: _parseInt(json['anomaly_count'] ?? json['anomalyCount']),
        avgTemperature:
            _parseDouble(json['avg_temperature'] ?? json['avgTemperature']),
        avgHumidity: _parseDouble(json['avg_humidity'] ?? json['avgHumidity']),
      );
    } catch (e) {
      print('❌ Error parsing DashboardSummary: $e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'total_devices': totalDevices,
      'recent_readings': recentReadings,
      'anomaly_count': anomalyCount,
      'avg_temperature': avgTemperature,
      'avg_humidity': avgHumidity,
    };
  }

  // Helper functions untuk parsing yang aman
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
}
