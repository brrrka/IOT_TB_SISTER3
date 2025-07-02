import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mqtt_provider.dart';
import '../providers/api_provider.dart';

class ConnectionStatusCard extends StatelessWidget {
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
                Icon(Icons.settings_ethernet, color: Colors.blue[800]),
                SizedBox(width: 8),
                Text(
                  'Connection Status',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Consumer2<MqttProvider, ApiProvider>(
              builder: (context, mqtt, api, child) {
                return Column(
                  children: [
                    // MQTT Connection Status
                    _buildConnectionRow(
                      'MQTT Broker',
                      mqtt.isConnected,
                      mqtt.isConnected
                          ? 'Connected to HiveMQ Cloud'
                          : 'Disconnected from broker',
                      Icons.wifi,
                      onTap: mqtt.isConnected ? null : () => mqtt.connect(),
                    ),
                    SizedBox(height: 12),

                    // FIXED: API Connection Status - Better detection logic
                    _buildConnectionRow(
                      'REST API Server',
                      _isApiHealthy(api),
                      _getApiStatusMessage(api),
                      Icons.cloud,
                      onTap: () => _testApiConnection(api),
                    ),

                    if (mqtt.isConnected) ...[
                      SizedBox(height: 16),
                      Divider(),
                      SizedBox(height: 8),
                      _buildStatsRow('Live Messages', '${mqtt.totalMessages}'),
                      _buildStatsRow('Active Devices', '${mqtt.activeDevices}'),
                      _buildStatsRow(
                          'Data Rate', '${_calculateDataRate(mqtt)} msg/min'),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Better API health detection
  bool _isApiHealthy(ApiProvider api) {
    // API is healthy if:
    // 1. Not currently loading AND
    // 2. Has some data (successful previous calls) OR no error
    // 3. Even if there's an error, if we have data, connection is working

    if (api.isLoading) return true; // Loading means attempting connection

    // If we have data, API connection is working
    if (api.hasData) return true;

    // If no data but also no error, connection might be OK but no data yet
    if (api.error == null) return true;

    // Only consider unhealthy if we have error AND no data
    return false;
  }

  // FIXED: Better API status messages
  String _getApiStatusMessage(ApiProvider api) {
    if (api.isLoading) {
      return 'Connecting to API server...';
    }

    if (api.hasData) {
      if (api.error != null) {
        return 'API connected (some errors)';
      }
      return 'API server responding normally';
    }

    if (api.error != null) {
      // Check if it's a timeout or network error
      if (api.error!.contains('timeout') ||
          api.error!.contains('TimeoutException')) {
        return 'API server timeout';
      } else if (api.error!.contains('SocketException') ||
          api.error!.contains('Connection')) {
        return 'Cannot reach API server';
      } else if (api.error!.contains('500')) {
        return 'API server error (500)';
      } else if (api.error!.contains('404')) {
        return 'API endpoint not found';
      } else {
        return 'API connection issues';
      }
    }

    return 'Waiting for API response';
  }

  // FIXED: Better API connection test
  Future<void> _testApiConnection(ApiProvider api) async {
    try {
      // Test basic connectivity first
      final isConnected = await api.testConnection();

      if (isConnected) {
        // If basic test passes, try to fetch some data
        await api.fetchSystemStatus(silent: false);
      }
    } catch (e) {
      print('Connection test failed: $e');
    }
  }

  // REMOVED: API Status Details (tidak diperlukan)
  // Widget _buildApiStatusDetails dan _buildApiDetailRow dihapus

  Widget _buildConnectionRow(
      String title, bool isConnected, String subtitle, IconData icon,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isConnected ? Colors.green[800] : Colors.red[800],
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isConnected ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (onTap != null && !isConnected) ...[
              SizedBox(width: 8),
              Icon(Icons.refresh, color: Colors.grey[600], size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDataRate(MqttProvider mqtt) {
    // FIXED: Better data rate calculation with null safety
    try {
      final readings = mqtt.realtimeReadings;
      if (readings.isEmpty) return '0';

      final now = DateTime.now();
      final recentReadings = readings.where((reading) {
        try {
          final readingTime = reading.dateTime;
          return now.difference(readingTime).inMinutes < 1;
        } catch (e) {
          return false;
        }
      }).length;

      return recentReadings.toString();
    } catch (e) {
      return '0';
    }
  }
}
