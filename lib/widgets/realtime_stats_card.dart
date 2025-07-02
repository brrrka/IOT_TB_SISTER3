import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mqtt_provider.dart';
import '../providers/api_provider.dart';
import '../models/sensor_reading.dart';

class RealtimeStatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<MqttProvider, ApiProvider>(
      builder: (context, mqtt, api, child) {
        final readings = mqtt.realtimeReadings;
        final deviceReadings = mqtt.latestDeviceReadings;

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.green[800]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Real-time Statistics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: mqtt.isConnected
                            ? Colors.green[100]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        mqtt.isConnected ? 'LIVE' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: mqtt.isConnected
                              ? Colors.green[800]
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Enhanced Statistics Grid with 24h anomaly data
                if (readings.isNotEmpty) ...[
                  _buildEnhancedStatsGrid(readings, deviceReadings, api),

                  SizedBox(height: 16),

                  // Enhanced: Anomaly Summary for 24h
                  _buildAnomalySummary24h(api),

                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),

                  // Temperature and Humidity Overview
                  _buildEnvironmentalOverview(readings),
                ] else ...[
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.sensors_off,
                            size: 48, color: Colors.grey[400]),
                        SizedBox(height: 8),
                        Text(
                          'No real-time data available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (!mqtt.isConnected) ...[
                          SizedBox(height: 8),
                          Text(
                            'Connect to MQTT to see live data',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
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

  // FIXED: Stats grid kembali ke 1 row dengan 4 data
  Widget _buildEnhancedStatsGrid(List<SensorReading> readings,
      Map<String, SensorReading> deviceReadings, ApiProvider api) {
    final hardwareCount =
        deviceReadings.values.where((r) => r.isHardware).length;
    final virtualCount = deviceReadings.values.where((r) => r.isVirtual).length;

    // ENHANCED: Use 24h anomaly data from batch processing
    final anomalies24h = api.totalEnhancedAnomalies; // From last 24h batches

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Total Readings',
            '${readings.length}',
            Icons.sensors,
            Colors.blue,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Hardware',
            '$hardwareCount',
            Icons.memory,
            Colors.green,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Virtual',
            '$virtualCount',
            Icons.computer,
            Colors.orange,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            '24h Anomalies',
            '$anomalies24h',
            Icons.warning,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // REMOVED: 24h Anomaly Summary (akan dipindah ke dashboard)
  Widget _buildAnomalySummary24h(ApiProvider api) {
    return SizedBox.shrink(); // Hilangkan dari home
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

  String _formatAnomalyType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.capitalize())
        .join(' ');
  }

  Widget _buildEnvironmentalOverview(List<SensorReading> readings) {
    if (readings.isEmpty) return SizedBox();

    final temperatures = readings.map((r) => r.temperature).toList();
    final humidities = readings.map((r) => r.humidity).toList();

    final avgTemp = temperatures.reduce((a, b) => a + b) / temperatures.length;
    final avgHumidity = humidities.reduce((a, b) => a + b) / humidities.length;
    final minTemp = temperatures.reduce((a, b) => a < b ? a : b);
    final maxTemp = temperatures.reduce((a, b) => a > b ? a : b);
    final minHumidity = humidities.reduce((a, b) => a < b ? a : b);
    final maxHumidity = humidities.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Environmental Conditions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildEnvironmentalCard(
                'Temperature',
                '${avgTemp.toStringAsFixed(1)}°C',
                'Range: ${minTemp.toStringAsFixed(1)}°C - ${maxTemp.toStringAsFixed(1)}°C',
                Icons.thermostat,
                Colors.red,
                _getTemperatureStatus(avgTemp),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildEnvironmentalCard(
                'Humidity',
                '${avgHumidity.toStringAsFixed(1)}%',
                'Range: ${minHumidity.toStringAsFixed(1)}% - ${maxHumidity.toStringAsFixed(1)}%',
                Icons.water_drop,
                Colors.blue,
                _getHumidityStatus(avgHumidity),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnvironmentalCard(
    String title,
    String value,
    String range,
    IconData icon,
    Color color,
    String status,
  ) {
    final statusColor = _getStatusColor(status);

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
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            range,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ENHANCED: Temperature status berdasarkan batch processing thresholds
  String _getTemperatureStatus(double temp) {
    if (temp < 15 || temp > 40) return 'Anomaly'; // Match batch processor
    if (temp < 18 || temp > 35) return 'Warning';
    return 'Normal';
  }

  // ENHANCED: Humidity status berdasarkan batch processing thresholds
  String _getHumidityStatus(double humidity) {
    if (humidity < 5 || humidity > 95)
      return 'Anomaly'; // Match batch processor
    if (humidity < 20 || humidity > 80) return 'Warning';
    return 'Normal';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Anomaly':
        return Colors.red;
      case 'Warning':
        return Colors.orange;
      case 'Normal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Extension to capitalize strings
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
