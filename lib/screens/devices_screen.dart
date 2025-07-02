import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_provider.dart';
import '../providers/mqtt_provider.dart';
import '../models/device_stats.dart';
import '../models/sensor_reading.dart';
import '../widgets/device_detail_dialog.dart';

class DevicesScreen extends StatefulWidget {
  @override
  _DevicesScreenState createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _showOnlineOnly = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDevices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeDevices() async {
    if (!_isInitialized) {
      await _loadDevices();
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _loadDevices() async {
    try {
      final apiProvider = context.read<ApiProvider>();
      await apiProvider.fetchDeviceStats();
    } catch (e) {
      print('❌ Error loading devices: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All Devices', icon: Icon(Icons.devices)),
            Tab(text: 'Hardware', icon: Icon(Icons.memory)),
            Tab(text: 'Virtual', icon: Icon(Icons.computer)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'online_only') {
                setState(() {
                  _showOnlineOnly = !_showOnlineOnly;
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'online_only',
                child: Row(
                  children: [
                    Icon(_showOnlineOnly
                        ? Icons.check_box
                        : Icons.check_box_outline_blank),
                    SizedBox(width: 8),
                    Text('Show Online Only'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search devices...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Device List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDeviceList(null), // All devices
                _buildDeviceList(true), // Hardware only
                _buildDeviceList(false), // Virtual only
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(bool? isHardware) {
    return Consumer2<ApiProvider, MqttProvider>(
      builder: (context, api, mqtt, child) {
        if (api.isLoading && !_isInitialized) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading devices...'),
                SizedBox(height: 8),
                Text(
                  'Please wait while we fetch device information',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          );
        }

        if (api.error != null &&
            api.deviceStats.isEmpty &&
            mqtt.latestDeviceReadings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading devices'),
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
                  onPressed: _loadDevices,
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        final devices = _getCombinedDeviceListSafe(
            api.deviceStats, mqtt.latestDeviceReadings);

        // Filter devices
        var filteredDevices = devices.where((device) {
          try {
            // Filter by search query
            if (_searchQuery.isNotEmpty &&
                !device.deviceId.toLowerCase().contains(_searchQuery)) {
              return false;
            }

            // Filter by device type
            if (isHardware != null) {
              final deviceIsHardware = _isHardwareDevice(device.deviceId);
              if (isHardware && !deviceIsHardware) return false;
              if (!isHardware && deviceIsHardware) return false;
            }

            // Filter by online status
            if (_showOnlineOnly) {
              final isOnline =
                  mqtt.latestDeviceReadings.containsKey(device.deviceId);
              if (!isOnline) return false;
            }

            return true;
          } catch (e) {
            print('❌ Error filtering device ${device.deviceId}: $e');
            return false;
          }
        }).toList();

        if (filteredDevices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.offline_share, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No devices found matching "$_searchQuery"'
                      : _showOnlineOnly
                          ? 'No online devices available'
                          : 'No devices available',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                if (api.error != null) ...[
                  SizedBox(height: 8),
                  Text(
                    'Connection issues may affect device list',
                    style: TextStyle(color: Colors.orange[600], fontSize: 12),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadDevices,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredDevices.length,
            itemBuilder: (context, index) {
              try {
                final device = filteredDevices[index];
                final isOnline =
                    mqtt.latestDeviceReadings.containsKey(device.deviceId);
                final latestReading =
                    mqtt.latestDeviceReadings[device.deviceId];

                return _buildDeviceCard(device, isOnline, latestReading);
              } catch (e) {
                print('❌ Error building device card at index $index: $e');
                return _buildErrorDeviceCard(index);
              }
            },
          ),
        );
      },
    );
  }

  List<DeviceStats> _getCombinedDeviceListSafe(
    List<DeviceStats> apiDevices,
    Map<String, SensorReading> mqttDevices,
  ) {
    final Map<String, DeviceStats> deviceMap = {};

    try {
      for (final device in apiDevices) {
        try {
          if (device.deviceId.isNotEmpty) {
            deviceMap[device.deviceId] = device;
          }
        } catch (e) {
          print('❌ Error processing API device: $e');
        }
      }

      for (final deviceId in mqttDevices.keys) {
        try {
          if (!deviceMap.containsKey(deviceId)) {
            final reading = mqttDevices[deviceId]!;
            deviceMap[deviceId] = DeviceStats(
              deviceId: deviceId,
              readingCount: 1,
              normalCount: 1,
              anomalyCount: 0,
              avgTemperature: reading.temperature,
              avgHumidity: reading.humidity,
              minTemperature: reading.temperature,
              maxTemperature: reading.temperature,
              minHumidity: reading.humidity,
              maxHumidity: reading.humidity,
              lastReadingTime: reading.timestamp,
              source: reading.source,
            );
          }
        } catch (e) {
          print('❌ Error processing MQTT device $deviceId: $e');
        }
      }
    } catch (e) {
      print('❌ Error in device combination: $e');
    }

    final deviceList = deviceMap.values.toList();
    try {
      deviceList.sort((a, b) => b.lastReadingTime.compareTo(a.lastReadingTime));
    } catch (e) {
      print('❌ Error sorting devices: $e');
    }

    return deviceList;
  }

  Widget _buildDeviceCard(
      DeviceStats device, bool isOnline, SensorReading? latestReading) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDeviceDetails(device, latestReading),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _getDeviceTypeColor(device.deviceId).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getDeviceIcon(device.deviceId),
                      color: _getDeviceTypeColor(device.deviceId),
                      size: 20,
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _getDeviceTypeText(device.deviceId),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOnline ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // UPDATED: Current Readings (tanpa status) - hanya data
              if (isOnline && latestReading != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildSimpleReadingItem(
                        'Temperature',
                        '${latestReading.temperature.toStringAsFixed(1)}°C',
                        Icons.thermostat,
                        Colors.red,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildSimpleReadingItem(
                        'Humidity',
                        '${latestReading.humidity.toStringAsFixed(1)}%',
                        Icons.water_drop,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Last Update Time - UPDATED: tanpa anomaly badge (akan dihandle batch processing)
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      'Last update: ${latestReading.displayTime}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Offline status
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.offline_bolt,
                          color: Colors.grey[600], size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Device is currently offline',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Historical Stats from batch processing
              if (device.readingCount > 0) ...[
                SizedBox(height: 12),
                Divider(),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Readings', '${device.readingCount}'),
                    _buildStatColumn('Avg Temp',
                        '${device.avgTemperature.toStringAsFixed(1)}°C'),
                    _buildStatColumn('Avg Humidity',
                        '${device.avgHumidity.toStringAsFixed(1)}%'),
                  ],
                ),
                // ENHANCED: Show anomaly stats from batch processing
                if (device.anomalyCount > 0) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning,
                            color: Colors.orange[700], size: 16),
                        SizedBox(width: 8),
                        Text(
                          '${device.anomalyCount} anomalies detected',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Simple reading item tanpa status
  Widget _buildSimpleReadingItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDeviceCard(int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error loading device #$index',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isHardwareDevice(String deviceId) {
    return ['sensor_001', 'sensor_002', 'sensor_003'].contains(deviceId);
  }

  Color _getDeviceTypeColor(String deviceId) {
    return _isHardwareDevice(deviceId) ? Colors.green : Colors.blue;
  }

  IconData _getDeviceIcon(String deviceId) {
    return _isHardwareDevice(deviceId) ? Icons.memory : Icons.computer;
  }

  String _getDeviceTypeText(String deviceId) {
    return _isHardwareDevice(deviceId) ? 'Hardware Sensor' : 'Virtual Sensor';
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showDeviceDetails(DeviceStats device, SensorReading? latestReading) {
    try {
      showDialog(
        context: context,
        builder: (context) => DeviceDetailDialog(
          device: device,
          latestReading: latestReading,
        ),
      );
    } catch (e) {
      print('❌ Error showing device details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening device details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
