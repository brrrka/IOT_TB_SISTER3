import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device_stats.dart';
import '../models/sensor_reading.dart';
import '../providers/api_provider.dart';
import '../screens/device_history_screen.dart';

class DeviceDetailDialog extends StatelessWidget {
  final DeviceStats device;
  final SensorReading? latestReading;

  const DeviceDetailDialog({
    Key? key,
    required this.device,
    this.latestReading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getDeviceTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDeviceIcon(),
                    color: _getDeviceTypeColor(),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.deviceId,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getDeviceTypeText(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),

            SizedBox(height: 20),

            // UPDATED: Current Data (dari MQTT, tanpa status)
            if (latestReading != null) ...[
              _buildSection(
                'Current Data',
                Icons.sensors,
                [
                  _buildDetailRow('Temperature',
                      '${latestReading!.temperature.toStringAsFixed(1)}°C'),
                  _buildDetailRow('Humidity',
                      '${latestReading!.humidity.toStringAsFixed(1)}%'),
                  _buildDetailRow('Last Update', latestReading!.displayTime),
                  _buildDetailRow('Source', latestReading!.source),
                ],
              ),
              SizedBox(height: 16),
            ],

            // ENHANCED: Statistics (dari batch processing data)
            Consumer<ApiProvider>(
              builder: (context, api, child) {
                return _buildSection(
                  'Batch Processing Statistics',
                  Icons.analytics,
                  [
                    _buildDetailRow('Total Readings', '${device.readingCount}'),
                    _buildDetailRow('Normal Readings', '${device.normalCount}'),
                    _buildDetailRow('Detected Anomalies', '${device.anomalyCount}'),
                    if (device.readingCount > 0)
                      _buildDetailRow('Anomaly Rate', 
                          '${(device.anomalyCount / device.readingCount * 100).toStringAsFixed(1)}%'),
                    _buildDetailRow('Avg Temperature',
                        '${device.avgTemperature.toStringAsFixed(1)}°C'),
                    _buildDetailRow('Avg Humidity',
                        '${device.avgHumidity.toStringAsFixed(1)}%'),
                    _buildDetailRow('Temp Range',
                        '${device.minTemperature.toStringAsFixed(1)}°C - ${device.maxTemperature.toStringAsFixed(1)}°C'),
                    _buildDetailRow('Humidity Range',
                        '${device.minHumidity.toStringAsFixed(1)}% - ${device.maxHumidity.toStringAsFixed(1)}%'),
                  ],
                );
              },
            ),

            SizedBox(height: 20),

            // UPDATED: Single Action Button - View History
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToHistory(context);
                },
                icon: Icon(Icons.timeline),
                label: Text('View Complete History'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]),
            SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  bool _isHardwareDevice() {
    return ['sensor_001', 'sensor_002', 'sensor_003'].contains(device.deviceId);
  }

  Color _getDeviceTypeColor() {
    return _isHardwareDevice() ? Colors.green : Colors.blue;
  }

  IconData _getDeviceIcon() {
    return _isHardwareDevice() ? Icons.memory : Icons.computer;
  }

  String _getDeviceTypeText() {
    return _isHardwareDevice() ? 'Hardware Sensor' : 'Virtual Sensor';
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceHistoryScreen(
          device: device,
          latestReading: latestReading,
        ),
      ),
    );
  }
}