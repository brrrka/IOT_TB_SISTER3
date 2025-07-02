import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/mqtt_provider.dart';
import '../providers/api_provider.dart';
import '../widgets/connection_status_card.dart';
import '../widgets/realtime_stats_card.dart';
import '../widgets/recent_readings_list.dart';
import '../widgets/quick_actions_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Start auto-refresh for API data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApiProvider>().startAutoRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            FaIcon(FontAwesomeIcons.microchip, size: 20),
            SizedBox(width: 8),
            Text('IoT Sensor Monitor'),
          ],
        ),
        actions: [
          Consumer<MqttProvider>(
            builder: (context, mqtt, child) {
              return Container(
                margin: EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mqtt.isConnected ? Icons.wifi : Icons.wifi_off,
                      color: mqtt.isConnected ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 4),
                    Text(
                      mqtt.isConnected ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: mqtt.isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status
              ConnectionStatusCard(),

              SizedBox(height: 16),

              // Real-time Statistics
              RealtimeStatsCard(),

              SizedBox(height: 16),

              // Quick Actions
              QuickActionsCard(),

              SizedBox(height: 24),

              // Recent Readings Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Real-time Data Stream',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Consumer<MqttProvider>(
                    builder: (context, mqtt, child) {
                      return Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: mqtt.isConnected
                              ? Colors.green[100]
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${mqtt.realtimeReadings.length} readings',
                          style: TextStyle(
                            fontSize: 12,
                            color: mqtt.isConnected
                                ? Colors.green[800]
                                : Colors.red[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Recent Readings List
              RecentReadingsList(),

              SizedBox(height: 80), // Bottom padding for navigation
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Reconnect MQTT button
          Consumer<MqttProvider>(
            builder: (context, mqtt, child) {
              if (!mqtt.isConnected) {
                return FloatingActionButton(
                  heroTag: "mqtt_reconnect",
                  mini: true,
                  onPressed: () => mqtt.connect(),
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.wifi, color: Colors.white),
                  tooltip: 'Reconnect MQTT',
                );
              }
              return SizedBox();
            },
          ),

          SizedBox(height: 8),

          // Main refresh button
          FloatingActionButton(
            heroTag: "main_refresh",
            onPressed: _refreshData,
            child: Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    final apiProvider = context.read<ApiProvider>();
    final mqttProvider = context.read<MqttProvider>();

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 8),
            Text('Refreshing data...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Refresh API data
      await Future.wait([
        apiProvider.fetchDashboardData(),
        apiProvider.fetchSystemStatus(),
        apiProvider.fetchRecentReadings(),
        apiProvider.fetchDeviceStats(),
      ]);

      // Reconnect MQTT if disconnected
      if (!mqttProvider.isConnected) {
        await mqttProvider.connect();
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Data refreshed successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Failed to refresh: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
