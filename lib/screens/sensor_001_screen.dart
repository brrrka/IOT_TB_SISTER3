  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import '../providers/mqtt_provider.dart';

  class Sensor001Screen extends StatefulWidget {
    @override
    _Sensor001ScreenState createState() => _Sensor001ScreenState();
  }

  class _Sensor001ScreenState extends State<Sensor001Screen>
      with TickerProviderStateMixin {
    late AnimationController _motionController;
    late AnimationController _rainController;

    @override
    void initState() {
      super.initState();
      _motionController = AnimationController(
        duration: Duration(milliseconds: 500),
        vsync: this,
      );
      _rainController = AnimationController(
        duration: Duration(milliseconds: 800),
        vsync: this,
      );
    }

    @override
    void dispose() {
      _motionController.dispose();
      _rainController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('sensor_001 Enhanced'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            Consumer<MqttProvider>(
              builder: (context, provider, child) {
                return Container(
                  margin: EdgeInsets.only(right: 16),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: provider.isConnected ? Colors.white : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    provider.isConnected ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      color: provider.isConnected ? Colors.green : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<MqttProvider>(
          builder: (context, provider, child) {
            final latestReading = provider.latestEnhancedReading;

            if (latestReading == null) {
              return _buildWaitingWidget();
            }

            if (latestReading.motionDetected == true) {
              _motionController.repeat(reverse: true);
            } else {
              _motionController.stop();
            }

            if (latestReading.isRaining == true) {
              _rainController.repeat();
            } else {
              _rainController.stop();
            }

            return RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(Duration(seconds: 1));
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeaderCard(latestReading, provider),
                    SizedBox(height: 16),
                    _buildQuickActionsCard(provider),
                    SizedBox(height: 16),
                    _buildDHTCard(latestReading),
                    SizedBox(height: 16),
                    _buildPIRCard(latestReading, provider),
                    SizedBox(height: 16),
                    _buildRainCard(latestReading, provider),
                    SizedBox(height: 16),
                    _buildSystemCard(latestReading, provider),
                    SizedBox(height: 16),
                    _buildHistoryCard(provider),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    Widget _buildWaitingWidget() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 24),
            Text(
              'Waiting for sensor_001 data...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'DHT11 + PIR + Rain Sensor',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    Widget _buildHeaderCard(
        EnhancedSensorReading reading, MqttProvider provider) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.sensors,
                      color: Colors.green,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'sensor_001 Enhanced',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Hardware Sensor with Enhanced Features',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Last update: ${reading.displayTime}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderStat('Messages', '${provider.enhancedMessageCount}',
                      Icons.message, Colors.blue),
                  _buildHeaderStat('PIR Triggers', '${provider.totalPirTriggers}',
                      Icons.directions_walk, Colors.red),
                  _buildHeaderStat(
                      'Rain Events',
                      '${provider.totalRainDetections}',
                      Icons.umbrella,
                      Colors.blue),
                  _buildHeaderStat(
                      'Uptime',
                      '${((reading.uptimeMs ?? 0) / (1000 * 60 * 60)).toStringAsFixed(1)}h',
                      Icons.timer,
                      Colors.green),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildHeaderStat(
        String label, String value, IconData icon, Color color) {
      return Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      );
    }

    Widget _buildQuickActionsCard(MqttProvider provider) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quick Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        provider.clearRealtimeData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Data cleared')),
                        );
                      },
                      icon: Icon(Icons.clear),
                      label: Text('Clear Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Export feature coming soon')),
                        );
                      },
                      icon: Icon(Icons.download),
                      label: Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildDHTCard(EnhancedSensorReading reading) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.thermostat, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('DHT11 Climate Sensor',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Spacer(),
                  if (reading.anomaly)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ANOMALY',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildLargeSensorCard(
                      'Temperature',
                      '${reading.temperature.toStringAsFixed(1)}°C',
                      Icons.thermostat,
                      _getTemperatureColor(reading.temperature),
                      reading.temperature < 20
                          ? 'Cold'
                          : reading.temperature > 35
                              ? 'Hot'
                              : 'Normal',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildLargeSensorCard(
                      'Humidity',
                      '${reading.humidity.toStringAsFixed(1)}%',
                      Icons.water_drop,
                      _getHumidityColor(reading.humidity),
                      reading.humidity < 30
                          ? 'Dry'
                          : reading.humidity > 80
                              ? 'Humid'
                              : 'Normal',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildPIRCard(EnhancedSensorReading reading, MqttProvider provider) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _motionController,
                    builder: (context, child) {
                      return Icon(
                        Icons.directions_walk,
                        color: reading.motionDetected == true
                            ? Colors.red
                                .withOpacity(0.5 + 0.5 * _motionController.value)
                            : Colors.grey,
                        size: 20,
                      );
                    },
                  ),
                  SizedBox(width: 8),
                  Text('PIR Motion Sensor',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: reading.motionDetected == true
                          ? Colors.red
                          : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          reading.motionDetected == true
                              ? Icons.person
                              : Icons.person_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          reading.motionDetected == true ? 'MOTION' : 'STILL',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: reading.motionDetected == true
                      ? Colors.red.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _buildPirStat('Current Status',
                                reading.motionStatus, Icons.radar)),
                        Expanded(
                            child: _buildPirStat('Session Triggers',
                                '${reading.triggerCount ?? 0}', Icons.numbers)),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _buildPirStat('Total Triggers',
                                '${provider.totalPirTriggers}', Icons.timeline)),
                        Expanded(
                            child: _buildPirStat(
                          'Time Since Trigger',
                          reading.timeSinceTrigger != null
                              ? '${(reading.timeSinceTrigger! / 1000).toStringAsFixed(0)}s'
                              : 'Never',
                          Icons.timer,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildRainCard(EnhancedSensorReading reading, MqttProvider provider) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _rainController,
                    builder: (context, child) {
                      return Icon(
                        _getRainIcon(reading.rainIntensity),
                        color: _getRainColor(reading.rainIntensity).withOpacity(
                            reading.isRaining == true
                                ? 0.5 + 0.5 * _rainController.value
                                : 1.0),
                        size: 20,
                      );
                    },
                  ),
                  SizedBox(width: 8),
                  Text('Rain Detection Sensor',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRainColor(reading.rainIntensity),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getRainEmoji(reading.rainIntensity),
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(width: 4),
                        Text(
                          reading.rainIntensity?.toUpperCase() ?? 'UNKNOWN',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getRainColor(reading.rainIntensity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _buildRainStat(
                                'Rain Level',
                                '${reading.rainLevelPercent ?? 0}%',
                                Icons.water)),
                        Expanded(
                            child: _buildRainStat(
                                'Analog Value',
                                '${reading.rainAnalogValue ?? 0}',
                                Icons.analytics)),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _buildRainStat(
                                'Digital State',
                                reading.rainDigitalState == true ? 'WET' : 'DRY',
                                Icons.sensors)),
                        Expanded(
                            child: _buildRainStat('Total Events',
                                '${provider.totalRainDetections}', Icons.event)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildSystemCard(
        EnhancedSensorReading reading, MqttProvider provider) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.computer, color: Colors.purple, size: 20),
                  SizedBox(width: 8),
                  Text('System Information',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSystemStat(
                      'Free Memory',
                      '${((reading.freeHeap ?? 0) / 1024).toStringAsFixed(1)} KB',
                      Icons.memory,
                      Colors.green,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildSystemStat(
                      'WiFi Signal',
                      '${reading.wifiRssi ?? 0} dBm',
                      Icons.wifi,
                      _getWifiSignalColor(reading.wifiRssi),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildHistoryCard(MqttProvider provider) {
      final recentReadings = provider.getEnhancedReadings(limit: 10);

      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: Colors.indigo, size: 20),
                  SizedBox(width: 8),
                  Text('Recent Activity',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Spacer(),
                  Text('${recentReadings.length} readings',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              SizedBox(height: 16),
              if (recentReadings.isEmpty)
                Container(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('No activity data available',
                        style: TextStyle(color: Colors.grey[600])),
                  ),
                )
              else
                ...recentReadings
                    .take(5)
                    .map((reading) => _buildHistoryItem(reading))
                    .toList(),
            ],
          ),
        ),
      );
    }

    Widget _buildHistoryItem(EnhancedSensorReading reading) {
      return Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              reading.displayTime,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700]),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text('${reading.temperature.toStringAsFixed(1)}°C'),
                  SizedBox(width: 8),
                  Text('${reading.humidity.toStringAsFixed(1)}%'),
                  SizedBox(width: 8),
                  if (reading.motionDetected == true)
                    Icon(Icons.directions_walk, size: 14, color: Colors.red),
                  if (reading.isRaining == true)
                    Icon(Icons.umbrella, size: 14, color: Colors.blue),
                ],
              ),
            ),
            if (reading.anomaly)
              Icon(Icons.warning, size: 16, color: Colors.orange),
          ],
        ),
      );
    }

    Widget _buildLargeSensorCard(
        String label, String value, IconData icon, Color color, String status) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(8)),
              child: Text(status,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    Widget _buildPirStat(String label, String value, IconData icon) {
      return Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ],
      );
    }

    Widget _buildRainStat(String label, String value, IconData icon) {
      return Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ],
      );
    }

    Widget _buildSystemStat(
        String label, String value, IconData icon, Color color) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      );
    }

    Color _getTemperatureColor(double temperature) {
      if (temperature < 15) return Colors.blue;
      if (temperature < 20) return Colors.lightBlue;
      if (temperature < 25) return Colors.green;
      if (temperature < 30) return Colors.orange;
      if (temperature < 35) return Colors.deepOrange;
      return Colors.red;
    }

    Color _getHumidityColor(double humidity) {
      if (humidity < 30) return Colors.orange;
      if (humidity < 40) return Colors.yellow[700]!;
      if (humidity < 60) return Colors.green;
      if (humidity < 80) return Colors.blue;
      return Colors.indigo;
    }

    IconData _getRainIcon(String? intensity) {
      switch (intensity) {
        case 'heavy':
          return Icons.thunderstorm;
        case 'moderate':
          return Icons.umbrella;
        case 'light':
          return Icons.grain;
        default:
          return Icons.wb_sunny;
      }
    }

    Color _getRainColor(String? intensity) {
      switch (intensity) {
        case 'heavy':
          return Colors.purple;
        case 'moderate':
          return Colors.blue;
        case 'light':
          return Colors.lightBlue;
        default:
          return Colors.orange;
      }
    }

    String _getRainEmoji(String? intensity) {
      switch (intensity) {
        case 'heavy':
          return '⛈️';
        case 'moderate':
          return '🌧️';
        case 'light':
          return '🌦️';
        default:
          return '☀️';
      }
    }

    Color _getWifiSignalColor(int? rssi) {
      if (rssi == null) return Colors.grey;
      if (rssi > -50) return Colors.green;
      if (rssi > -70) return Colors.orange;
      return Colors.red;
    }
  }
