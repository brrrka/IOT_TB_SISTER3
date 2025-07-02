class BatchSummary {
  final String batchId;
  final String processedAt;
  final int batchTimestamp;
  final int totalReadings;
  final int normalReadings;
  final int anomalyReadings;
  final double anomalyPercentage;
  final int deviceCount;
  final double temperatureAvg;
  final double humidityAvg;
  final String filename;

  BatchSummary({
    required this.batchId,
    required this.processedAt,
    required this.batchTimestamp,
    required this.totalReadings,
    required this.normalReadings,
    required this.anomalyReadings,
    required this.anomalyPercentage,
    required this.deviceCount,
    required this.temperatureAvg,
    required this.humidityAvg,
    required this.filename,
  });

  factory BatchSummary.fromJson(Map<String, dynamic> json) {
    try {
      return BatchSummary(
        batchId: _parseString(json['batch_id'] ?? json['batchId']),
        processedAt: _parseString(json['processed_at'] ?? json['processedAt']),
        batchTimestamp:
            _parseInt(json['batch_timestamp'] ?? json['batchTimestamp']),
        totalReadings:
            _parseInt(json['total_readings'] ?? json['totalReadings']),
        normalReadings:
            _parseInt(json['normal_readings'] ?? json['normalReadings']),
        anomalyReadings:
            _parseInt(json['anomaly_readings'] ?? json['anomalyReadings']),
        anomalyPercentage: _parseDouble(
            json['anomaly_percentage'] ?? json['anomalyPercentage']),
        deviceCount: _parseInt(json['device_count'] ?? json['deviceCount']),
        temperatureAvg:
            _parseDouble(json['temperature_avg'] ?? json['temperatureAvg']),
        humidityAvg: _parseDouble(json['humidity_avg'] ?? json['humidityAvg']),
        filename: _parseString(json['filename'] ?? ''),
      );
    } catch (e) {
      print('❌ Error parsing BatchSummary: $e');
      print('❌ JSON data: $json');

      // Return safe default
      return BatchSummary(
        batchId: json['batch_id']?.toString() ?? 'unknown',
        processedAt: json['processed_at']?.toString() ?? '',
        batchTimestamp: 0,
        totalReadings: 0,
        normalReadings: 0,
        anomalyReadings: 0,
        anomalyPercentage: 0.0,
        deviceCount: 0,
        temperatureAvg: 0.0,
        humidityAvg: 0.0,
        filename: json['filename']?.toString() ?? '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_id': batchId,
      'processed_at': processedAt,
      'batch_timestamp': batchTimestamp,
      'total_readings': totalReadings,
      'normal_readings': normalReadings,
      'anomaly_readings': anomalyReadings,
      'anomaly_percentage': anomalyPercentage,
      'device_count': deviceCount,
      'temperature_avg': temperatureAvg,
      'humidity_avg': humidityAvg,
      'filename': filename,
    };
  }

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

  // Utility getters
  DateTime get processedDateTime {
    try {
      return DateTime.parse(processedAt);
    } catch (e) {
      return DateTime.fromMillisecondsSinceEpoch(batchTimestamp * 1000);
    }
  }

  String get processedTimeDisplay {
    try {
      final dateTime = processedDateTime;
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }

  String get anomalyPercentageDisplay {
    return '${anomalyPercentage.toStringAsFixed(1)}%';
  }

  bool get hasData => totalReadings > 0;
  bool get hasAnomalies => anomalyReadings > 0;

  @override
  String toString() {
    return 'BatchSummary(batchId: $batchId, totalReadings: $totalReadings, anomalies: $anomalyReadings)';
  }
}
