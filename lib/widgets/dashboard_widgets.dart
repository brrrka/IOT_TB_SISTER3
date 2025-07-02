// widgets/recent_readings_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mqtt_provider.dart';
import '../models/sensor_reading.dart';

class RecentReadingsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MqttProvider>(
      builder: (context, mqtt, child) {
        final readings = mqtt.realtimeReadings.take(20).toList();

        if (readings.isEmpty) {
          return Card(
            child: Container(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sensors_off, size: 48, color: Colors.grey[400]),
                    SizedBox(height: 8),
                    Text(
                      'No real-time data',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (!mqtt.isConnected) ...[
                      SizedBox(height: 4),
                      Text(
                        'Connect to MQTT to see live data',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.stream, color: Colors.blue[800]),
                    SizedBox(width: 8),
                    Text(
                      'Live Data Stream',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${readings.length} readings',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              Container(
                height: 300,
                child: ListView.builder(
                  itemCount: readings.length,
                  itemBuilder: (context, index) {
                    final reading = readings[index];
                    return _buildReadingItem(reading);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadingItem(SensorReading reading) {
    final statusColor = _getStatusColor(reading.overallStatus);

    return ListTile(
      dense: true,
      leading: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: reading.isHardware ? Colors.green[100] : Colors.blue[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          reading.isHardware ? Icons.memory : Icons.computer,
          size: 16,
          color: reading.isHardware ? Colors.green[800] : Colors.blue[800],
        ),
      ),
      title: Row(
        children: [
          Text(
            reading.deviceId,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              reading.overallStatus,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        '${reading.temperature.toStringAsFixed(1)}°C • ${reading.humidity.toStringAsFixed(1)}% • ${reading.displayTime}',
        style: TextStyle(fontSize: 11),
      ),
      trailing: reading.anomaly
          ? Icon(Icons.warning, color: Colors.orange, size: 16)
          : null,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Critical':
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

// widgets/quick_actions_card.dart
class QuickActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.purple[800]),
                SizedBox(width: 8),
                Text(
                  'Quick Actions',
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
                  child: _buildActionButton(
                    'Dashboard',
                    Icons.dashboard,
                    Colors.blue,
                    () => Navigator.pushNamed(context, '/dashboard'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Devices',
                    Icons.devices,
                    Colors.green,
                    () => Navigator.pushNamed(context, '/devices'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Settings',
                    Icons.settings,
                    Colors.grey,
                    () => Navigator.pushNamed(context, '/settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// widgets/anomaly_alerts_card.dart
class AnomalyAlertsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MqttProvider>(
      builder: (context, mqtt, child) {
        final anomalies = mqtt.getRecentAnomalies();

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
                    Text(
                      'Anomaly Alerts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: anomalies.isEmpty
                            ? Colors.green[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${anomalies.length} alerts',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: anomalies.isEmpty
                              ? Colors.green[800]
                              : Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (anomalies.isEmpty) ...[
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 48),
                        SizedBox(height: 8),
                        Text(
                          'No anomalies detected',
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
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: anomalies.length.clamp(0, 10),
                      itemBuilder: (context, index) {
                        final anomaly = anomalies[index];
                        return ListTile(
                          dense: true,
                          leading: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.warning,
                              color: Colors.orange[800],
                              size: 16,
                            ),
                          ),
                          title: Text(
                            anomaly.deviceId,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'T:${anomaly.temperature.toStringAsFixed(1)}°C H:${anomaly.humidity.toStringAsFixed(1)}% • ${anomaly.displayTime}',
                            style: TextStyle(fontSize: 10),
                          ),
                          trailing: Icon(Icons.chevron_right, size: 16),
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
}
