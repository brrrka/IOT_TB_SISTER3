import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/device_stats.dart';
import '../models/sensor_reading.dart';
import '../providers/api_provider.dart';

class DeviceHistoryScreen extends StatefulWidget {
  final DeviceStats device;
  final SensorReading? latestReading;

  const DeviceHistoryScreen({
    Key? key,
    required this.device,
    this.latestReading,
  }) : super(key: key);

  @override
  _DeviceHistoryScreenState createState() => _DeviceHistoryScreenState();
}

class _DeviceHistoryScreenState extends State<DeviceHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;

  // Data variables
  Map<String, dynamic>? _deviceAnomalyData;
  List<SensorReading>? _deviceReadings24h;
  List<SensorReading>? _deviceReadings7d; // Changed from 30d to 7d

  // Anomaly-related data
  List<SensorReading> _anomalyReadings = [];
  Map<String, int> _anomalyTypeBreakdown = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDeviceHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiProvider = context.read<ApiProvider>();

      // Load device readings first (these are more reliable)
      print('📱 Loading device readings for ${widget.device.deviceId}...');

      // Load 24h readings
      final readings24h = await apiProvider.fetchDeviceReadings(
        widget.device.deviceId,
        hours: 24,
        limit: 200,
      );

      // Load 7-day readings (reduced from 30 days to avoid 422 error)
      final readings7d = await apiProvider.fetchDeviceReadings(
        widget.device.deviceId,
        hours: 168, // 7 days = 168 hours (reduced from 720)
        limit: 300, // Reduced limit
      );

      // Try to load device anomaly analysis (handle if it fails)
      Map<String, dynamic>? anomalyData;
      try {
        print('🚨 Attempting to load anomaly analysis...');
        anomalyData = await apiProvider.fetchDeviceAnomalyAnalysis(
          widget.device.deviceId,
          hours: 24,
        );
        print('✅ Anomaly analysis loaded successfully');
      } catch (anomalyError) {
        print('⚠️ Anomaly analysis failed: $anomalyError');
        // Continue without anomaly data - we'll extract from readings instead
      }

      // Extract anomalies from readings if API failed
      if (anomalyData == null && readings24h != null) {
        print('📊 Extracting anomalies from readings...');
        _extractAnomaliesFromReadings(readings24h);
      }

      setState(() {
        _deviceAnomalyData = anomalyData;
        _deviceReadings24h = readings24h;
        _deviceReadings7d = readings7d;
        _isLoading = false;
      });

      print('✅ Device history loaded successfully');
    } catch (e) {
      print('❌ Error loading device history: $e');
      setState(() {
        _errorMessage = 'Failed to load device data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _extractAnomaliesFromReadings(List<SensorReading> readings) {
    // Extract anomalies from readings and create basic analysis
    _anomalyReadings = readings.where((r) => r.anomaly).toList();

    // Create type breakdown from anomaly types if available
    _anomalyTypeBreakdown.clear();
    for (final reading in _anomalyReadings) {
      if (reading.anomalyTypes != null) {
        for (final type in reading.anomalyTypes!) {
          _anomalyTypeBreakdown[type] = (_anomalyTypeBreakdown[type] ?? 0) + 1;
        }
      } else {
        // If no specific types, just count as 'detected'
        _anomalyTypeBreakdown['detected'] =
            (_anomalyTypeBreakdown['detected'] ?? 0) + 1;
      }
    }

    print('📊 Extracted ${_anomalyReadings.length} anomalies from readings');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.device.deviceId),
            Text(
              _getDeviceTypeText(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 16)),
            Tab(text: 'Anomalies', icon: Icon(Icons.warning, size: 16)),
            Tab(text: 'Charts', icon: Icon(Icons.show_chart, size: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDeviceHistory,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading device history...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[400]),
                      SizedBox(height: 16),
                      Text('Error loading data'),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDeviceHistory,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildAnomaliesTab(),
                    _buildChartsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Status Card
          if (widget.latestReading != null) ...[
            _buildCurrentStatusCard(),
            SizedBox(height: 16),
          ],
          // Statistics Summary Card
          _buildStatisticsSummaryCard(),
          SizedBox(height: 16),
          // Quick Anomaly Overview
          _buildQuickAnomalyOverview(),
          // Performance Metrics - DIHAPUS sesuai request
        ],
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    final reading = widget.latestReading!;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors, color: Colors.blue[700], size: 20),
                SizedBox(width: 8),
                Text(
                  'Current Live Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        reading.anomaly ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reading.anomaly ? 'ANOMALY' : 'NORMAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          reading.anomaly ? Colors.red[800] : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Temperature',
                    '${reading.temperature.toStringAsFixed(1)}°C',
                    Icons.thermostat,
                    Colors.red,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Humidity',
                    '${reading.humidity.toStringAsFixed(1)}%',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Last update: ${reading.displayTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Spacer(),
                Text(
                  'Source: ${reading.source}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            // Show anomaly types if present
            if (reading.anomaly &&
                reading.anomalyTypes != null &&
                reading.anomalyTypes!.isNotEmpty) ...[
              SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: reading.anomalyTypes!.map((type) {
                  return Chip(
                    label: Text(type, style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.red[100],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSummaryCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple[700], size: 20),
                SizedBox(width: 8),
                Text(
                  'Batch Processing Statistics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // GridView dengan height yang proper
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildStatTile(
                    'Total Readings',
                    '${widget.device.readingCount}',
                    Icons.sensors,
                    Colors.blue),
                _buildStatTile(
                    'Normal Readings',
                    '${widget.device.normalCount}',
                    Icons.check_circle,
                    Colors.green),
                _buildStatTile('Anomalies', '${widget.device.anomalyCount}',
                    Icons.warning, Colors.orange),
                _buildStatTile(
                    'Anomaly Rate',
                    '${widget.device.readingCount > 0 ? (widget.device.anomalyCount / widget.device.readingCount * 100).toStringAsFixed(1) : 0}%',
                    Icons.analytics,
                    Colors.red),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            // Summary stats dengan layout horizontal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildStatColumn('Avg Temp',
                      '${widget.device.avgTemperature.toStringAsFixed(1)}°C'),
                ),
                Expanded(
                  child: _buildStatColumn('Avg Humidity',
                      '${widget.device.avgHumidity.toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildStatColumn('Temp Range',
                      '${widget.device.minTemperature.toStringAsFixed(1)}°C - ${widget.device.maxTemperature.toStringAsFixed(1)}°C'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAnomalyOverview() {
    // Use data from API if available, otherwise use extracted data
    final totalAnomalies = _deviceAnomalyData?['summary']?['total_anomalies'] ??
        _anomalyReadings.length;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                SizedBox(width: 8),
                Text(
                  'Recent Anomalies (Last 24h)', // CLARIFY INI DATA 24 JAM TERAKHIR
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: totalAnomalies > 0
                        ? Colors.orange[100]
                        : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalAnomalies found',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: totalAnomalies > 0
                          ? Colors.orange[800]
                          : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Live anomaly detection from recent sensor data',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic),
            ),
            if (totalAnomalies > 0) ...[
              SizedBox(height: 16),
              // Show patterns from anomaly data or extracted data
              if (_deviceAnomalyData?['patterns'] != null) ...[
                _buildAnomalyPatterns(_deviceAnomalyData!['patterns']),
              ] else if (_anomalyTypeBreakdown.isNotEmpty) ...[
                _buildExtractedAnomalyPatterns(),
              ],
            ] else ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green[700], size: 16),
                    SizedBox(width: 8),
                    Text(
                      'No anomalies detected in the last 24 hours',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExtractedAnomalyPatterns() {
    return Container(
      width: double.infinity, // FULL WIDTH
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Anomaly Types:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _anomalyTypeBreakdown.entries.map((entry) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Text('${entry.key}: ${entry.value}',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Colors.indigo[700], size: 20),
                SizedBox(width: 8),
                Text(
                  'Performance Metrics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceItem(
                    'Data Quality',
                    '${widget.device.readingCount > 0 ? ((widget.device.normalCount / widget.device.readingCount) * 100).toStringAsFixed(1) : 0}%',
                    Icons.high_quality,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildPerformanceItem(
                    'Uptime',
                    _calculateUptime(),
                    Icons.timer,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomaliesTab() {
    // Use extracted anomalies if API data not available
    final hasApiData = _deviceAnomalyData != null;
    final totalAnomalies = hasApiData
        ? (_deviceAnomalyData!['summary']?['total_anomalies'] ?? 0)
        : _anomalyReadings.length;

    if (totalAnomalies == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
            SizedBox(height: 16),
            Text('No anomalies detected in the last 24 hours'),
            SizedBox(height: 8),
            Text('This device is operating normally',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Anomaly Summary
          _buildAnomalySummaryCard(),
          SizedBox(height: 16),
          // Anomaly Patterns
          _buildAnomalyPatternsCard(),
          SizedBox(height: 16),
          // Recent Anomalies List
          _buildRecentAnomaliesCard(),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.grey[100],
            child: TabBar(
              labelColor: Colors.blue[800],
              unselectedLabelColor: Colors.grey[600],
              tabs: [
                Tab(text: '24 Hours'),
                Tab(text: '7 Days'), // Changed from 30 Days
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildChartView(_deviceReadings24h, '24h'),
                _buildChartView(_deviceReadings7d, '7d'), // Changed from 30d
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartView(List<SensorReading>? readings, String period) {
    if (readings == null || readings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('No data available for $period'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadDeviceHistory,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Temperature Chart
          _buildTemperatureChart(readings, period),
          SizedBox(height: 24),
          // Humidity Chart
          _buildHumidityChart(readings, period),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart(List<SensorReading> readings, String period) {
    if (readings.isEmpty) {
      return Container(
        height: 200,
        child: Center(child: Text('No temperature data for $period')),
      );
    }

    // Pisahkan data normal dan anomali juga untuk temperature
    final normalSpots = <FlSpot>[];
    final anomalySpots = <FlSpot>[];

    for (int i = 0; i < readings.length; i++) {
      final spot = FlSpot(i.toDouble(), readings[i].temperature);
      if (readings[i].anomaly) {
        anomalySpots.add(spot);
      } else {
        normalSpots.add(spot);
      }
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Temperature Trend ($period)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                // Legend sederhana
                Row(
                  children: [
                    Container(width: 12, height: 2, color: Colors.red),
                    SizedBox(width: 4),
                    Text('Normal', style: TextStyle(fontSize: 10)),
                    SizedBox(width: 8),
                    Container(width: 12, height: 2, color: Colors.orange),
                    SizedBox(width: 4),
                    Text('Anomaly', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}°C',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval:
                            readings.length > 20 ? readings.length / 8 : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < readings.length) {
                            final reading = readings[index];
                            return Text(
                              reading.displayTime.split(' ')[1].substring(0, 5),
                              style: TextStyle(fontSize: 8),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    // ANOMALY LINE FIRST (di belakang) - warna oranye
                    if (anomalySpots.isNotEmpty)
                      LineChartBarData(
                        spots: anomalySpots,
                        isCurved: true,
                        color: Colors.orange,
                        barWidth: 3, // Sedikit lebih tebal biar keliatan
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.orange.withOpacity(0.1),
                        ),
                      ),
                    // NORMAL LINE SECOND (di depan) - warna merah
                    if (normalSpots.isNotEmpty)
                      LineChartBarData(
                        spots: normalSpots,
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.red.withOpacity(0.1),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHumidityChart(List<SensorReading> readings, String period) {
    // Similar to temperature chart
    if (readings.isEmpty) {
      return Container(
        height: 200,
        child: Center(child: Text('No humidity data for $period')),
      );
    }

    final normalSpots = <FlSpot>[];
    final anomalySpots = <FlSpot>[];

    for (int i = 0; i < readings.length; i++) {
      final spot = FlSpot(i.toDouble(), readings[i].humidity);
      if (readings[i].anomaly) {
        anomalySpots.add(spot);
      } else {
        normalSpots.add(spot);
      }
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Humidity Trend ($period)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}%',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval:
                            readings.length > 20 ? readings.length / 10 : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < readings.length) {
                            final reading = readings[index];
                            return Text(
                              reading.displayTime.split(' ')[1].substring(0, 5),
                              style: TextStyle(fontSize: 8),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    // Normal readings
                    if (normalSpots.isNotEmpty)
                      LineChartBarData(
                        spots: normalSpots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.1),
                        ),
                      ),
                    // Anomaly readings
                    if (anomalySpots.isNotEmpty)
                      LineChartBarData(
                        spots: anomalySpots,
                        isCurved: false,
                        color: Colors.orange,
                        barWidth: 0,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.orange,
                              strokeWidth: 2,
                              strokeColor: Colors.red,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyChart(List<SensorReading> readings, String period) {
    final anomalies = readings.where((r) => r.anomaly).toList();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anomaly Distribution ($period)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: anomalies.length.clamp(0, 20),
                itemBuilder: (context, index) {
                  final anomaly = anomalies[index];
                  return Container(
                    width: 80,
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          anomaly.displayTime.split(' ')[1].substring(0, 5),
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${anomaly.temperature.toStringAsFixed(1)}°C',
                          style: TextStyle(fontSize: 9, color: Colors.red[700]),
                        ),
                        Text(
                          '${anomaly.humidity.toStringAsFixed(1)}%',
                          style:
                              TextStyle(fontSize: 9, color: Colors.blue[700]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 4),
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPerformanceItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomalyPatterns(Map<String, dynamic> patterns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('API Patterns:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        if (patterns['type_frequency'] != null)
          Wrap(
            spacing: 4,
            children: (patterns['type_frequency'] as Map<String, dynamic>)
                .entries
                .map((entry) {
              return Chip(
                label: Text('${entry.key}: ${entry.value}',
                    style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.orange[100],
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAnomalySummaryCard() {
    final hasApiData = _deviceAnomalyData != null;
    final summary = hasApiData ? (_deviceAnomalyData!['summary'] ?? {}) : {};
    final totalAnomalies = hasApiData
        ? (summary['total_anomalies'] ?? 0)
        : _anomalyReadings.length;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Anomaly Summary',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Spacer(),
                if (!hasApiData)
                  Chip(
                    label: Text('Extracted', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.blue[100],
                  ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total', '$totalAnomalies', Colors.red),
                _buildSummaryItem(
                    'Most Common',
                    hasApiData
                        ? (summary['most_common_type'] ?? 'N/A')
                        : (_anomalyTypeBreakdown.isNotEmpty
                            ? _anomalyTypeBreakdown.keys.first
                            : 'N/A'),
                    Colors.orange),
                // HAPUS PEAK HOUR
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyPatternsCard() {
    final hasApiData = _deviceAnomalyData != null;

    return Container(
      width: double.infinity, // FULL WIDTH HANDPHONE
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anomaly Patterns',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              if (hasApiData && _deviceAnomalyData!['patterns'] != null) ...[
                _buildAnomalyPatterns(_deviceAnomalyData!['patterns']),
              ] else if (_anomalyTypeBreakdown.isNotEmpty) ...[
                _buildExtractedAnomalyPatterns(),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('No pattern data available',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAnomaliesCard() {
    final hasApiData = _deviceAnomalyData != null;
    final anomalies = hasApiData
        ? (_deviceAnomalyData!['recent_anomalies'] ?? [])
        : _anomalyReadings
            .map((r) => {
                  'device_id': r.deviceId,
                  'temperature': r.temperature,
                  'humidity': r.humidity,
                  'formatted_time': r.displayTime,
                  'anomaly_types': r.anomalyTypes ?? ['detected'],
                })
            .toList();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Recent Anomaly Details (24h)', // CLARIFY 24H
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Spacer(),
                if (!hasApiData)
                  Chip(
                    label: Text('Extracted', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.blue[100],
                  ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Individual anomaly readings from the last 24 hours',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            if (anomalies.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('No recent anomalies found',
                    style: TextStyle(color: Colors.green[700]),
                    textAlign: TextAlign.center),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: anomalies.length.clamp(0, 10),
                itemBuilder: (context, index) {
                  final anomaly = anomalies[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading:
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                      title: Text(
                          'T: ${anomaly['temperature']}°C, H: ${anomaly['humidity']}%',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(anomaly['formatted_time']?.toString() ?? '',
                              style: TextStyle(fontSize: 10)),
                          if (anomaly['anomaly_types'] != null)
                            Wrap(
                              spacing: 4,
                              children: (anomaly['anomaly_types'] as List)
                                  .map((type) {
                                return Chip(
                                  label: Text(type.toString(),
                                      style: TextStyle(fontSize: 8)),
                                  backgroundColor: Colors.red[100],
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  String _calculateUptime() {
    // Simple uptime calculation based on last reading time
    if (widget.latestReading != null) {
      final now = DateTime.now();
      final lastUpdate = widget.latestReading!.dateTime;
      final diff = now.difference(lastUpdate);
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    }
    return 'Unknown';
  }

  bool _isHardwareDevice() {
    return ['sensor_001', 'sensor_002', 'sensor_003']
        .contains(widget.device.deviceId);
  }

  String _getDeviceTypeText() {
    return _isHardwareDevice() ? 'Hardware Sensor' : 'Virtual Sensor';
  }
}
