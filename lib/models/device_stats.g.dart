// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceStats _$DeviceStatsFromJson(Map<String, dynamic> json) => DeviceStats(
      deviceId: json['device_id'] as String,
      readingCount: (json['reading_count'] as num).toInt(),
      avgTemperature: (json['avg_temperature'] as num).toDouble(),
      avgHumidity: (json['avg_humidity'] as num).toDouble(),
      minTemperature: (json['min_temperature'] as num).toDouble(),
      maxTemperature: (json['max_temperature'] as num).toDouble(),
      minHumidity: (json['min_humidity'] as num).toDouble(),
      maxHumidity: (json['max_humidity'] as num).toDouble(),
      lastReadingTime: (json['last_reading_time'] as num).toInt(),
      source: json['source'] as String,
    );

Map<String, dynamic> _$DeviceStatsToJson(DeviceStats instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'reading_count': instance.readingCount,
      'avg_temperature': instance.avgTemperature,
      'avg_humidity': instance.avgHumidity,
      'min_temperature': instance.minTemperature,
      'max_temperature': instance.maxTemperature,
      'min_humidity': instance.minHumidity,
      'max_humidity': instance.maxHumidity,
      'last_reading_time': instance.lastReadingTime,
      'source': instance.source,
    };
