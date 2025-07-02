import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_provider.dart';
import '../widgets/temperature_humidity_chart.dart';

// FIXED: Stat card with proper constraints to prevent overflow
class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const DashboardStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(2),
      child: Container(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  Spacer(),
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4),
            Flexible(
              flex: 1,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Flexible(
              flex: 1,
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ENHANCED: Anomaly alerts using batch processing data
class EnhancedAnomalyAlertsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ApiProvider>(
      builder: (context, api, child) {
        // Use enhanced anomaly data from batch processing
        final recentAnomalies = api.recentAnomalies; // From enhanced API
        final anomalySummary = api.anomalySummary;
        final totalAnomalies = api.totalEnhancedAnomalies;

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Latest Anomalies',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: totalAnomalies == 0
                            ? Colors.green[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalAnomalies detected',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: totalAnomalies == 0
                              ? Colors.green[800]
                              : Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),

                // Enhanced: Show detection rate if available
                if (anomalySummary != null) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.analytics,
                            size: 12, color: Colors.blue[700]),
                        SizedBox(width: 4),
                        Text(
                          'Detection Rate: ${anomalySummary.anomalyPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${anomalySummary.affectedDevices} devices affected',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 16),

                if (recentAnomalies.isEmpty) ...[
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 48),
                        SizedBox(height: 8),
                        Text(
                          'No anomalies in latest batch',
                          style: TextStyle(color: Colors.green[700]),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'All sensors operating normally',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Enhanced: Show anomaly breakdown if available
                  if (anomalySummary != null &&
                      anomalySummary.typeBreakdown.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anomaly Types:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: anomalySummary.typeBreakdown.entries
                                .map((entry) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getAnomalyTypeColor(entry.key)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${_formatAnomalyType(entry.key)}: ${entry.value}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: _getAnomalyTypeColor(entry.key),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                  ],

                  // Enhanced: Anomaly list with better formatting
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: recentAnomalies.length.clamp(0, 10),
                      itemBuilder: (context, index) {
                        final anomaly = recentAnomalies[index];
                        final severityColor =
                            _getSeverityColor(anomaly.severity);

                        return ListTile(
                          dense: true,
                          leading: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: severityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              _getSeverityIcon(anomaly.severity),
                              color: severityColor,
                              size: 16,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  anomaly.deviceId,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: severityColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  anomaly.severity.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: severityColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'T:${anomaly.temperature.toStringAsFixed(1)}°C H:${anomaly.humidity.toStringAsFixed(1)}% • ${anomaly.formattedTime}',
                                style: TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (anomaly.anomalyTypes.isNotEmpty)
                                Text(
                                  'Types: ${anomaly.anomalyTypes.map((type) => _formatAnomalyType(type)).join(', ')}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: severityColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (anomaly.batchId != null)
                                Text(
                                  'Batch: ${anomaly.batchId}',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.grey[500],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.amber;
      default:
        return Colors.orange;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      default:
        return Icons.warning_amber;
    }
  }

  Color _getAnomalyTypeColor(String type) {
    if (type.contains('temperature')) {
      return Colors.red;
    } else if (type.contains('humidity')) {
      return Colors.blue;
    } else if (type.contains('sudden')) {
      return Colors.purple;
    } else {
      return Colors.orange;
    }
  }

  String _formatAnomalyType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.capitalize())
        .join(' ');
  }
}

// Extension to capitalize strings
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

// FIXED: Device status grid with proper aspect ratio and constraints
class DeviceStatusGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ApiProvider>(
      builder: (context, api, child) {
        final devices = api.deviceStats;

        if (devices.isEmpty) {
          return Card(
            child: Container(
              height: 150,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.offline_bolt, size: 48, color: Colors.grey[400]),
                    SizedBox(height: 8),
                    Text(
                      'No device data available',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Check API connection',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.0,
          ),
          itemCount: devices.length.clamp(0, 6),
          itemBuilder: (context, index) {
            final device = devices[index];

            bool isHardware = device.isHardware;
            bool hasAnomalies = device.anomalyCount > 0;

            return Card(
              margin: EdgeInsets.all(1),
              child: Container(
                padding: EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Icon(
                            isHardware ? Icons.memory : Icons.computer,
                            size: 14,
                            color: isHardware ? Colors.green : Colors.blue,
                          ),
                          SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              device.deviceId,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color:
                                  hasAnomalies ? Colors.orange : Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${device.avgTemperature.toStringAsFixed(1)}°C',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${device.avgHumidity.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${device.readingCount} readings',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (hasAnomalies)
                            Flexible(
                              child: Text(
                                '${device.anomalyCount} anomalies',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isInitialized = false;
  ApiProvider? _apiProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apiProvider = context.read<ApiProvider>();
  }

  Future<void> _initializeDashboard() async {
    if (!_isInitialized && mounted) {
      final apiProvider = context.read<ApiProvider>();
      // ENHANCED: Fetch all data including enhanced anomalies
      await apiProvider.fetchAllData();
      apiProvider.startAutoRefresh(interval: Duration(seconds: 30));

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _refreshDashboard() async {
    if (mounted) {
      final apiProvider = context.read<ApiProvider>();
      await apiProvider.fetchAllData();
    }
  }

  @override
  void dispose() {
    _apiProvider?.stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Dashboard'),
            SizedBox(width: 8),
            Consumer<ApiProvider>(
              builder: (context, api, child) {
                if (api.isLoading) {
                  return SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  );
                }
                return Icon(
                  api.hasData ? Icons.wifi : Icons.wifi_off,
                  size: 16,
                  color: api.hasData ? Colors.green : Colors.red,
                );
              },
            ),
          ],
        ),
        actions: [
          Consumer<ApiProvider>(
            builder: (context, api, child) {
              return IconButton(
                icon: Icon(Icons.refresh),
                onPressed: api.isLoading ? null : _refreshDashboard,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: Consumer<ApiProvider>(
          builder: (context, api, child) {
            if (api.isLoading && !api.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading dashboard data...'),
                    SizedBox(height: 8),
                    Text(
                      'Fetching latest batch processing results',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              );
            }

            if (api.error != null && !api.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Unable to load dashboard'),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        api.error!,
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshDashboard,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced: Connection Status Banner with batch info
                  // if (api.error != null)
                  //   Container(
                  //     width: double.infinity,
                  //     padding: EdgeInsets.all(8),
                  //     margin: EdgeInsets.only(bottom: 12),
                  //     decoration: BoxDecoration(
                  //       color: Colors.orange[100],
                  //       borderRadius: BorderRadius.circular(8),
                  //       border: Border.all(color: Colors.orange[300]!),
                  //     ),
                  //     child: Row(
                  //       children: [
                  //         Icon(Icons.warning,
                  //             color: Colors.orange[700], size: 16),
                  //         SizedBox(width: 8),
                  //         Expanded(
                  //           child: Text(
                  //             'Connection issues detected. Data may be outdated.',
                  //             style: TextStyle(
                  //               color: Colors.orange[700],
                  //               fontSize: 12,
                  //               fontWeight: FontWeight.w500,
                  //             ),
                  //           ),
                  //         ),
                  //         Text(
                  //           'Last update: ${api.lastUpdateTime}',
                  //           style: TextStyle(
                  //             color: Colors.orange[600],
                  //             fontSize: 10,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),

                  // Enhanced: Dashboard Statistics Cards with batch processing data
                  _buildEnhancedStatsGrid(),

                  SizedBox(height: 16),

                  // Temperature & Humidity Chart
                  _buildChartsSection(),

                  SizedBox(height: 16),

                  // Device Status Grid
                  _buildDeviceStatusSection(),

                  SizedBox(height: 16),

                  // Enhanced: Anomaly Alerts from batch processing
                  _buildEnhancedAnomalySection(),

                  SizedBox(height: 60),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ENHANCED: Stats grid using batch processing data
  Widget _buildEnhancedStatsGrid() {
    return Consumer<ApiProvider>(
      builder: (context, api, child) {
        final dashboard = api.dashboardData;
        final summary = dashboard?.summary;
        final anomalySummary = api.anomalySummary;

        return GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.8,
          children: [
            DashboardStatCard(
              title: 'Active Devices',
              value: '${summary?.totalDevices ?? api.deviceStats.length}',
              icon: Icons.devices,
              color: Colors.blue,
              subtitle: 'Connected now',
            ),
            DashboardStatCard(
              title: 'Recent Readings',
              value: '${summary?.recentReadings ?? api.recentReadings.length}',
              icon: Icons.sensors,
              color: Colors.green,
              subtitle: 'Last 6 hours',
            ),
            DashboardStatCard(
              title: 'Batch Anomalies',
              value: '${api.totalEnhancedAnomalies}', // Use enhanced anomalies
              icon: Icons.warning,
              color: Colors.orange,
              subtitle: anomalySummary != null
                  ? '${anomalySummary.anomalyPercentage.toStringAsFixed(1)}% rate'
                  : 'Latest batch',
            ),
            DashboardStatCard(
              title: 'Avg Temp',
              value: summary?.avgTemperature != null
                  ? '${summary!.avgTemperature.toStringAsFixed(1)}°C'
                  : api.normalReadings.isNotEmpty
                      ? '${(api.normalReadings.map((r) => r.temperature).reduce((a, b) => a + b) / api.normalReadings.length).toStringAsFixed(1)}°C'
                      : '0.0°C',
              icon: Icons.thermostat,
              color: Colors.red,
              subtitle: 'Current average',
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          child: Text(
            'Environmental Trends',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: TemperatureHumidityChart(),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Device Status',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/devices');
              },
              child: Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 16),
        DeviceStatusGrid(),
      ],
    );
  }

  // ENHANCED: Anomaly section using batch processing data with severity distribution
  Widget _buildEnhancedAnomalySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Latest Anomalies',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Consumer<ApiProvider>(
              builder: (context, api, child) {
                final totalAnomalies = api.totalEnhancedAnomalies;
                final detectionQuality = api.detectionQuality;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (totalAnomalies > 0)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalAnomalies total',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    SizedBox(height: 2),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        detectionQuality,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),

        SizedBox(height: 16),

        // NEW: Severity Distribution Card
        Consumer<ApiProvider>(
          builder: (context, api, child) {
            final severityBreakdown = api.severityBreakdown;
            final totalAnomalies = api.totalEnhancedAnomalies;

            if (totalAnomalies > 0 && severityBreakdown.isNotEmpty) {
              return Column(
                children: [
                  _buildSeverityDistributionCard(
                      severityBreakdown, totalAnomalies),
                  SizedBox(height: 16),
                ],
              );
            }
            return SizedBox.shrink();
          },
        ),

        EnhancedAnomalyAlertsCard(), // Use enhanced anomaly card
      ],
    );
  }

  // NEW: Severity Distribution Card
  Widget _buildSeverityDistributionCard(
      Map<String, int> severityBreakdown, int totalAnomalies) {
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
                  'Anomaly Severity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalAnomalies total',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Severity bars
            ...severityBreakdown.entries.map((entry) {
              final severity = entry.key;
              final count = entry.value;
              final percentage = (count / totalAnomalies * 100);
              final color = _getSeverityColor(severity);

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              severity.capitalize(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '(${percentage.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            SizedBox(height: 8),

            // Summary row
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSeveritySummaryItem(
                    'High Risk',
                    (severityBreakdown['critical'] ?? 0) +
                        (severityBreakdown['high'] ?? 0),
                    Colors.red,
                  ),
                  _buildSeveritySummaryItem(
                    'Medium Risk',
                    severityBreakdown['medium'] ?? 0,
                    Colors.orange,
                  ),
                  _buildSeveritySummaryItem(
                    'Low Risk',
                    severityBreakdown['low'] ?? 0,
                    Colors.amber,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeveritySummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.amber;
      default:
        return Colors.orange;
    }
  }
}
