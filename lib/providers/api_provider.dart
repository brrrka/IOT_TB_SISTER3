import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/sensor_reading.dart';
import '../models/device_stats.dart';
import '../models/batch_summary.dart';
import '../models/dashboard_data.dart';

// NEW: Enhanced Anomaly Models
class AnomalyReading {
  final String deviceId;
  final int timestamp;
  final String formattedTime;
  final double temperature;
  final double humidity;
  final String source;
  final List<String> anomalyTypes;
  final String severity;
  final String? batchId;

  AnomalyReading({
    required this.deviceId,
    required this.timestamp,
    required this.formattedTime,
    required this.temperature,
    required this.humidity,
    required this.source,
    required this.anomalyTypes,
    required this.severity,
    this.batchId,
  });

  factory AnomalyReading.fromJson(Map<String, dynamic> json) {
    return AnomalyReading(
      deviceId: json['device_id'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      formattedTime: json['formatted_time'] ?? '',
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      source: json['source'] ?? '',
      anomalyTypes: List<String>.from(json['anomaly_types'] ?? []),
      severity: json['severity'] ?? 'unknown',
      batchId: json['batch_id'],
    );
  }
}

class AnomalySummary {
  final int totalAnomalies;
  final double anomalyPercentage;
  final int affectedDevices;
  final Map<String, int> severityBreakdown;
  final Map<String, int> typeBreakdown;
  final Map<String, dynamic> timeRange;

  AnomalySummary({
    required this.totalAnomalies,
    required this.anomalyPercentage,
    required this.affectedDevices,
    required this.severityBreakdown,
    required this.typeBreakdown,
    required this.timeRange,
  });

  factory AnomalySummary.fromJson(Map<String, dynamic> json) {
    return AnomalySummary(
      totalAnomalies: json['total_anomalies'] ?? 0,
      anomalyPercentage: (json['anomaly_percentage'] ?? 0.0).toDouble(),
      affectedDevices: json['affected_devices'] ?? 0,
      severityBreakdown:
          Map<String, int>.from(json['severity_breakdown'] ?? {}),
      typeBreakdown: Map<String, int>.from(json['type_breakdown'] ?? {}),
      timeRange: Map<String, dynamic>.from(json['time_range'] ?? {}),
    );
  }
}

class BatchAnomalyReport {
  final String batchId;
  final String processedAt;
  final int totalReadings;
  final int normalReadings;
  final int anomalyReadings;
  final double anomalyPercentage;
  final double detectionRate;
  final Map<String, int> anomalyBreakdown;
  final List<AnomalyReading> topAnomalies;

  BatchAnomalyReport({
    required this.batchId,
    required this.processedAt,
    required this.totalReadings,
    required this.normalReadings,
    required this.anomalyReadings,
    required this.anomalyPercentage,
    required this.detectionRate,
    required this.anomalyBreakdown,
    required this.topAnomalies,
  });

  factory BatchAnomalyReport.fromJson(Map<String, dynamic> json) {
    return BatchAnomalyReport(
      batchId: json['batch_id'] ?? '',
      processedAt: json['processed_at'] ?? '',
      totalReadings: json['total_readings'] ?? 0,
      normalReadings: json['normal_readings'] ?? 0,
      anomalyReadings: json['anomaly_readings'] ?? 0,
      anomalyPercentage: (json['anomaly_percentage'] ?? 0.0).toDouble(),
      detectionRate: (json['detection_rate'] ?? 0.0).toDouble(),
      anomalyBreakdown: Map<String, int>.from(json['anomaly_breakdown'] ?? {}),
      topAnomalies: (json['top_anomalies'] as List? ?? [])
          .map((item) => AnomalyReading.fromJson(item))
          .toList(),
    );
  }
}

class ApiProvider extends ChangeNotifier {
  // API Configuration (adjust IP to your server)
  static const String baseUrl = 'http://192.168.135.253:8000';

  bool _isLoading = false;
  String? _error;
  DashboardData? _dashboardData;
  List<SensorReading> _recentReadings = [];
  List<DeviceStats> _deviceStats = [];
  List<BatchSummary> _batches = [];
  Map<String, dynamic>? _systemStatus;

  // NEW: Enhanced Anomaly Data
  Map<String, dynamic>? _enhancedAnomaliesData;
  AnomalySummary? _anomalySummary;
  List<AnomalyReading> _recentAnomalies = [];
  Map<String, dynamic>? _realtimeAnomalyStream;
  Map<String, dynamic>? _anomalyStatistics;

  // Getters - Original
  bool get isLoading => _isLoading;
  String? get error => _error;
  DashboardData? get dashboardData => _dashboardData;
  List<SensorReading> get recentReadings => _recentReadings;
  List<DeviceStats> get deviceStats => _deviceStats;
  List<BatchSummary> get batches => _batches;
  Map<String, dynamic>? get systemStatus => _systemStatus;

  // NEW: Enhanced Anomaly Getters
  Map<String, dynamic>? get enhancedAnomaliesData => _enhancedAnomaliesData;
  AnomalySummary? get anomalySummary => _anomalySummary;
  List<AnomalyReading> get recentAnomalies => _recentAnomalies;
  Map<String, dynamic>? get realtimeAnomalyStream => _realtimeAnomalyStream;
  Map<String, dynamic>? get anomalyStatistics => _anomalyStatistics;

  // HTTP Client with timeout
  final http.Client _httpClient = http.Client();
  static const Duration _timeout = Duration(seconds: 15); // Increased timeout

  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<T?> _makeRequest<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    bool updateLoading = true,
  }) async {
    try {
      if (updateLoading) {
        _setLoading(true);
      }
      _setError(null);

      print('🌐 API Request: $baseUrl$endpoint');

      final response = await _httpClient.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return fromJson(data);
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ API Error: $e');
      _setError(e.toString());
      return null;
    } finally {
      if (updateLoading) {
        _setLoading(false);
      }
    }
  }

  Future<List<T>?> _makeListRequest<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    bool updateLoading = true,
  }) async {
    try {
      if (updateLoading) {
        _setLoading(true);
      }
      _setError(null);

      print('🌐 API List Request: $baseUrl$endpoint');

      final response = await _httpClient.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final List<T> results = [];
        for (int i = 0; i < data.length; i++) {
          try {
            final item = data[i];
            if (item is Map<String, dynamic>) {
              final parsedItem = fromJson(item);
              results.add(parsedItem);
            }
          } catch (e) {
            print('❌ Error parsing item $i: $e');
            // Continue parsing other items
          }
        }

        return results;
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ API List Error: $e');
      _setError(e.toString());
      return null;
    } finally {
      if (updateLoading) {
        _setLoading(false);
      }
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _safeNotifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      _safeNotifyListeners();
    }
  }

  // ============= ORIGINAL API METHODS (PRESERVED) =============

  Future<void> fetchDashboardData({bool silent = false}) async {
    final data = await _makeRequest<DashboardData>(
      '/api/dashboard',
      (json) => DashboardData.fromJson(json),
      updateLoading: !silent,
    );

    if (data != null) {
      _dashboardData = data;
      if (!silent) {
        _safeNotifyListeners();
      }
    }
  }

  Future<void> fetchSystemStatus({bool silent = false}) async {
    final data = await _makeRequest<Map<String, dynamic>>(
      '/api/status',
      (json) => json,
      updateLoading: !silent,
    );

    if (data != null) {
      _systemStatus = data;
      if (!silent) {
        _safeNotifyListeners();
      }
    }
  }

  Future<void> fetchRecentReadings({
    int limit = 100,
    int hours = 24,
    bool silent = false,
  }) async {
    final data = await _makeListRequest<SensorReading>(
      '/api/readings?limit=$limit&hours=$hours&include_anomalies=true',
      (json) => SensorReading.fromJsonSafe(json),
      updateLoading: !silent,
    );

    if (data != null) {
      _recentReadings = data;
      if (!silent) {
        _safeNotifyListeners();
      }
    }
  }

  Future<List<SensorReading>?> fetchDeviceReadings(
    String deviceId, {
    int limit = 100,
    int hours = 24,
    bool silent = false,
  }) async {
    return await _makeListRequest<SensorReading>(
      '/api/devices/$deviceId/readings?limit=$limit&hours=$hours&include_anomalies=true',
      (json) => SensorReading.fromJsonSafe(json),
      updateLoading: !silent,
    );
  }

  Future<void> fetchDeviceStats({bool silent = false}) async {
    final data = await _makeListRequest<DeviceStats>(
      '/api/devices',
      (json) => DeviceStats.fromJson(json),
      updateLoading: !silent,
    );

    if (data != null) {
      _deviceStats = data;
      if (!silent) {
        _safeNotifyListeners();
      }
    }
  }

  Future<void> fetchBatches({
    int limit = 10,
    int offset = 0,
    bool silent = false,
  }) async {
    final data = await _makeListRequest<BatchSummary>(
      '/api/batches?limit=$limit&offset=$offset',
      (json) => BatchSummary.fromJson(json),
      updateLoading: !silent,
    );

    if (data != null) {
      _batches = data;
      if (!silent) {
        _safeNotifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>?> fetchBatchDetails(
    String batchId, {
    bool silent = false,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/api/batches/$batchId',
      (json) => json,
      updateLoading: !silent,
    );
  }

  // ============= NEW: ENHANCED ANOMALY API METHODS =============

  Future<void> fetchEnhancedAnomalies({
    int hours = 24,
    String? deviceId,
    String? severity,
    String? anomalyType,
    int limit = 100,
    bool silent = false,
  }) async {
    try {
      if (!silent) _setLoading(true);
      _setError(null);

      String endpoint = '/api/anomalies?hours=$hours&limit=$limit';
      if (deviceId != null) endpoint += '&device_id=$deviceId';
      if (severity != null) endpoint += '&severity=$severity';
      if (anomalyType != null) endpoint += '&anomaly_type=$anomalyType';

      print('🌐 Enhanced Anomalies Request: $baseUrl$endpoint');

      final response = await _httpClient.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic>) {
          _enhancedAnomaliesData = data;

          // Parse summary
          if (data['summary'] != null) {
            _anomalySummary = AnomalySummary.fromJson(data['summary']);
          }

          // Parse anomalies list
          if (data['anomalies'] is List) {
            _recentAnomalies = (data['anomalies'] as List)
                .map((item) => AnomalyReading.fromJson(item))
                .toList();
          }

          if (!silent) {
            _safeNotifyListeners();
          }
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Error fetching enhanced anomalies: $e');
      _setError(e.toString());
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<BatchAnomalyReport?> fetchBatchAnomalyReport(
    String batchId, {
    bool silent = false,
  }) async {
    return await _makeRequest<BatchAnomalyReport>(
      '/api/anomalies/batch/$batchId',
      (json) => BatchAnomalyReport.fromJson(json),
      updateLoading: !silent,
    );
  }

  Future<void> fetchAnomalyStatistics({
    int hours = 24,
    String groupBy = 'hour',
    bool silent = false,
  }) async {
    final data = await _makeRequest<Map<String, dynamic>>(
      '/api/anomalies/stats?hours=$hours&group_by=$groupBy',
      (json) => json,
      updateLoading: !silent,
    );

    if (data != null) {
      _anomalyStatistics = data;
      if (!silent) {
        _safeNotifyListeners();
      }
    }
  }

  Future<void> fetchRealtimeAnomalyStream({
    int lastMinutes = 10,
    bool silent = false,
  }) async {
    final data = await _makeRequest<Map<String, dynamic>>(
      '/api/anomalies/realtime?last_minutes=$lastMinutes',
      (json) => json,
      updateLoading: !silent,
    );

    if (data != null) {
      _realtimeAnomalyStream = data;
      if (!silent) {
        _safeNotifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>?> fetchDeviceAnomalyAnalysis(
    String deviceId, {
    int hours = 24,
    bool silent = false,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/api/anomalies/devices/$deviceId?hours=$hours',
      (json) => json,
      updateLoading: !silent,
    );
  }

  // ============= LEGACY ANOMALY METHOD (PRESERVED) =============

  Future<void> fetchAnomalies({int hours = 24, bool silent = false}) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/anomalies/legacy?hours=$hours'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic>) {
          // Keep legacy format for backward compatibility
          final legacyAnomaliesData = {
            'total_anomalies': data['total_anomalies'] ?? 0,
            'breakdown': data['breakdown'] ?? {},
            'anomalies': [],
            'query_params': data['query_params'] ?? {},
            'last_checked':
                data['last_checked'] ?? DateTime.now().toIso8601String(),
          };

          if (data['anomalies'] is List) {
            final anomaliesList = <Map<String, dynamic>>[];
            for (final item in data['anomalies']) {
              try {
                if (item is Map<String, dynamic>) {
                  final reading = SensorReading.fromJsonSafe(item);
                  anomaliesList.add(reading.toJson());
                }
              } catch (e) {
                print('❌ Error parsing legacy anomaly item: $e');
              }
            }
            legacyAnomaliesData['anomalies'] = anomaliesList;
          }

          if (!silent) {
            _safeNotifyListeners();
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching legacy anomalies: $e');
      _setError(e.toString());
    }
  }

  // ============= ENHANCED DATA FETCHING =============

  Future<void> fetchAllData({bool silent = false}) async {
    try {
      if (!silent) _setLoading(true);

      // Fetch all data concurrently but handle errors individually
      final futures = [
        fetchDashboardData(silent: true),
        fetchSystemStatus(silent: true),
        fetchRecentReadings(silent: true),
        fetchDeviceStats(silent: true),
        fetchBatches(silent: true),
        fetchEnhancedAnomalies(silent: true), // Use enhanced anomalies
        fetchRealtimeAnomalyStream(silent: true),
      ];

      await Future.wait(futures, eagerError: false);

      if (!silent) {
        _setLoading(false);
        _safeNotifyListeners();
      }
    } catch (e) {
      print('❌ Error fetching all data: $e');
      _setError(e.toString());
      if (!silent) _setLoading(false);
    }
  }

  // ============= UTILITY METHODS =============

  Future<bool> testConnection() async {
    try {
      final response =
          await _httpClient.get(Uri.parse('$baseUrl/')).timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void clearData() {
    _dashboardData = null;
    _recentReadings.clear();
    _deviceStats.clear();
    _batches.clear();
    _systemStatus = null;

    // Clear enhanced anomaly data
    _enhancedAnomaliesData = null;
    _anomalySummary = null;
    _recentAnomalies.clear();
    _realtimeAnomalyStream = null;
    _anomalyStatistics = null;

    _error = null;
    _safeNotifyListeners();
  }

  // Auto-refresh functionality
  Timer? _refreshTimer;

  void startAutoRefresh({Duration interval = const Duration(seconds: 30)}) {
    stopAutoRefresh();
    _refreshTimer = Timer.periodic(interval, (_) {
      fetchAllData(silent: true);
    });
    print('🔄 Auto-refresh started (${interval.inSeconds}s interval)');
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    print('⏹️ Auto-refresh stopped');
  }

  @override
  void dispose() {
    stopAutoRefresh();
    _httpClient.close();
    super.dispose();
  }

  // ============= HELPER METHODS =============

  List<SensorReading> get normalReadings =>
      _recentReadings.where((r) => !r.anomaly).toList();

  List<SensorReading> get anomalyReadings =>
      _recentReadings.where((r) => r.anomaly).toList();

  // Enhanced anomaly helpers
  int get totalEnhancedAnomalies => _anomalySummary?.totalAnomalies ?? 0;

  double get enhancedAnomalyPercentage =>
      _anomalySummary?.anomalyPercentage ?? 0.0;

  int get affectedDevices => _anomalySummary?.affectedDevices ?? 0;

  Map<String, int> get severityBreakdown =>
      _anomalySummary?.severityBreakdown ?? {};

  Map<String, int> get typeBreakdown => _anomalySummary?.typeBreakdown ?? {};

  // Legacy compatibility
  int get totalAnomalies => totalEnhancedAnomalies;

  Map<String, dynamic> get anomalyBreakdown => {
        'by_type': typeBreakdown,
        'by_severity': severityBreakdown,
      };

  bool get hasData => _dashboardData != null || _recentReadings.isNotEmpty;

  String get lastUpdateTime {
    if (_dashboardData?.lastUpdate != null) {
      try {
        final dateTime = DateTime.parse(_dashboardData!.lastUpdate!);
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return 'Unknown';
      }
    }
    return 'No data';
  }

  // NEW: Real-time anomaly metrics
  double get liveAnomalyRate =>
      _realtimeAnomalyStream?['stream_info']?['live_anomaly_rate']
          ?.toDouble() ??
      0.0;

  int get realtimeTotalReadings =>
      _realtimeAnomalyStream?['stream_info']?['total_readings'] ?? 0;

  int get realtimeTotalAnomalies =>
      _realtimeAnomalyStream?['stream_info']?['total_anomalies'] ?? 0;

  List<dynamic> get latestAnomalies =>
      _realtimeAnomalyStream?['latest_anomalies'] ?? [];

  // NEW: Detection quality metrics
  String get detectionQuality {
    final rate = enhancedAnomalyPercentage;
    if (rate >= 10.0) return 'High Detection';
    if (rate >= 5.0) return 'Medium Detection';
    if (rate >= 1.0) return 'Low Detection';
    return 'Minimal Detection';
  }

  // NEW: System health indicator
  String get systemHealthStatus {
    if (_systemStatus == null) return 'Unknown';
    final status = _systemStatus!['status'];
    final lastBatchTime = _systemStatus!['last_batch_time'];

    if (status == 'active' && lastBatchTime != null) {
      return 'Healthy';
    } else if (status == 'active') {
      return 'Active';
    } else {
      return 'Inactive';
    }
  }
}
