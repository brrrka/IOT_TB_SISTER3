// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardData _$DashboardDataFromJson(Map<String, dynamic> json) =>
    DashboardData(
      status: json['status'] as String,
      lastUpdate: json['last_update'] as String?,
      lastChecked: json['last_checked'] as String,
      dataFreshness: json['data_freshness'] as String,
      summary: json['summary'] == null
          ? null
          : DashboardSummary.fromJson(json['summary'] as Map<String, dynamic>),
      recentReadings: (json['recent_readings'] as List<dynamic>?)
          ?.map((e) => SensorReading.fromJson(e as Map<String, dynamic>))
          .toList(),
      topDevices: (json['top_devices'] as List<dynamic>?)
          ?.map((e) => DeviceStats.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentAnomalies: (json['recent_anomalies'] as List<dynamic>?)
          ?.map((e) => SensorReading.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DashboardDataToJson(DashboardData instance) =>
    <String, dynamic>{
      'status': instance.status,
      'last_update': instance.lastUpdate,
      'last_checked': instance.lastChecked,
      'data_freshness': instance.dataFreshness,
      'summary': instance.summary,
      'recent_readings': instance.recentReadings,
      'top_devices': instance.topDevices,
      'recent_anomalies': instance.recentAnomalies,
    };

DashboardSummary _$DashboardSummaryFromJson(Map<String, dynamic> json) =>
    DashboardSummary(
      totalDevices: (json['total_devices'] as num).toInt(),
      recentReadings: (json['recent_readings'] as num).toInt(),
      anomalyCount: (json['anomaly_count'] as num).toInt(),
      avgTemperature: (json['avg_temperature'] as num).toDouble(),
      avgHumidity: (json['avg_humidity'] as num).toDouble(),
    );

Map<String, dynamic> _$DashboardSummaryToJson(DashboardSummary instance) =>
    <String, dynamic>{
      'total_devices': instance.totalDevices,
      'recent_readings': instance.recentReadings,
      'anomaly_count': instance.anomalyCount,
      'avg_temperature': instance.avgTemperature,
      'avg_humidity': instance.avgHumidity,
    };
