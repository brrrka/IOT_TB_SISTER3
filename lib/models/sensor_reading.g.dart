// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_reading.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SensorReading _$SensorReadingFromJson(Map<String, dynamic> json) =>
    SensorReading(
      deviceId: json['device_id'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      source: json['source'] as String,
      msgCount: (json['msg_count'] as num).toInt(),
      anomaly: json['anomaly'] as bool,
      formattedTime: json['formatted_time'] as String?,
      batchId: json['batch_id'] as String?,
      isProcessedAnomaly: json['is_processed_anomaly'] as bool?,
      anomalyTypes: (json['anomaly_types'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SensorReadingToJson(SensorReading instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'timestamp': instance.timestamp,
      'temperature': instance.temperature,
      'humidity': instance.humidity,
      'source': instance.source,
      'msg_count': instance.msgCount,
      'anomaly': instance.anomaly,
      'formatted_time': instance.formattedTime,
      'batch_id': instance.batchId,
      'is_processed_anomaly': instance.isProcessedAnomaly,
      'anomaly_types': instance.anomalyTypes,
    };
