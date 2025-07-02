// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatchSummary _$BatchSummaryFromJson(Map<String, dynamic> json) => BatchSummary(
      batchId: json['batch_id'] as String,
      processedAt: json['processed_at'] as String,
      batchTimestamp: (json['batch_timestamp'] as num).toInt(),
      totalReadings: (json['total_readings'] as num).toInt(),
      validReadings: (json['valid_readings'] as num).toInt(),
      filteredAnomalies: (json['filtered_anomalies'] as num).toInt(),
      deviceCount: (json['device_count'] as num).toInt(),
      temperatureAvg: (json['temperature_avg'] as num).toDouble(),
      humidityAvg: (json['humidity_avg'] as num).toDouble(),
      filename: json['filename'] as String,
    );

Map<String, dynamic> _$BatchSummaryToJson(BatchSummary instance) =>
    <String, dynamic>{
      'batch_id': instance.batchId,
      'processed_at': instance.processedAt,
      'batch_timestamp': instance.batchTimestamp,
      'total_readings': instance.totalReadings,
      'valid_readings': instance.validReadings,
      'filtered_anomalies': instance.filteredAnomalies,
      'device_count': instance.deviceCount,
      'temperature_avg': instance.temperatureAvg,
      'humidity_avg': instance.humidityAvg,
      'filename': instance.filename,
    };
