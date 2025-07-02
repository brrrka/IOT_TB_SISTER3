import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/mqtt_provider.dart';
import '../providers/api_provider.dart';
import '../models/sensor_reading.dart';

class TemperatureHumidityChart extends StatefulWidget {
  @override
  _TemperatureHumidityChartState createState() =>
      _TemperatureHumidityChartState();
}

class _TemperatureHumidityChartState extends State<TemperatureHumidityChart> {
  bool _showTemperature = true;
  String _selectedDevice = 'All';

  // NEW: Data storage for individual sensors
  Map<String, List<SensorReading>> _deviceDataHistory = {};
  static const int MAX_DATA_POINTS = 50; // Limit data points per device

  @override
  Widget build(BuildContext context) {
    return Consumer2<MqttProvider, ApiProvider>(
      builder: (context, mqtt, api, child) {
        final readings = _getChartData(mqtt, api);

        // FIXED: Update device data history
        _updateDeviceDataHistory(readings);

        if (readings.isEmpty) {
          return Container(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                  SizedBox(height: 8),
                  Text(
                    'No chart data available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          height: 400, // Increased height for better visualization
          child: Column(
            children: [
              // Temperature/Humidity Toggle
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showTemperature = true;
                        });
                      },
                      icon: Icon(Icons.thermostat, size: 16),
                      label: Text('Temperature'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _showTemperature ? Colors.red : Colors.grey[300],
                        foregroundColor:
                            _showTemperature ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showTemperature = false;
                        });
                      },
                      icon: Icon(Icons.water_drop, size: 16),
                      label: Text('Humidity'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            !_showTemperature ? Colors.blue : Colors.grey[300],
                        foregroundColor:
                            !_showTemperature ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Device Filter
              Row(
                children: [
                  Icon(Icons.device_hub, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDevice,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, size: 16),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          items: _getDeviceOptions(readings),
                          onChanged: (String? value) {
                            setState(() {
                              _selectedDevice = value ?? 'All';
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Chart Type Indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _selectedDevice == 'All'
                      ? Colors.orange[100]
                      : Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _selectedDevice == 'All'
                      ? 'Bar Chart - Latest values per device'
                      : 'Line Chart - $_selectedDevice over time',
                  style: TextStyle(
                    fontSize: 10,
                    color: _selectedDevice == 'All'
                        ? Colors.orange[800]
                        : Colors.green[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Chart
              Expanded(
                child: _selectedDevice == 'All'
                    ? _buildBarChart(readings)
                    : _buildLineChart(
                        _deviceDataHistory[_selectedDevice] ?? []),
              ),
            ],
          ),
        );
      },
    );
  }

  List<SensorReading> _getChartData(MqttProvider mqtt, ApiProvider api) {
    final Set<String> seenReadings = {};
    final List<SensorReading> allReadings = [];

    // Add MQTT real-time data first (more recent)
    for (final reading in mqtt.realtimeReadings) {
      final key = '${reading.deviceId}_${reading.timestamp}';
      if (!seenReadings.contains(key)) {
        seenReadings.add(key);
        allReadings.add(reading);
      }
    }

    // Add API recent readings (if not already included)
    for (final reading in api.recentReadings) {
      final key = '${reading.deviceId}_${reading.timestamp}';
      if (!seenReadings.contains(key)) {
        seenReadings.add(key);
        allReadings.add(reading);
      }
    }

    allReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return allReadings;
  }

  void _updateDeviceDataHistory(List<SensorReading> readings) {
    for (final reading in readings) {
      final deviceId = reading.deviceId;

      // Initialize device data if not exists
      if (!_deviceDataHistory.containsKey(deviceId)) {
        _deviceDataHistory[deviceId] = [];
      }

      // Add reading if not already exists (based on timestamp)
      final existingTimestamps =
          _deviceDataHistory[deviceId]!.map((r) => r.timestamp).toSet();

      if (!existingTimestamps.contains(reading.timestamp)) {
        _deviceDataHistory[deviceId]!.add(reading);

        // Sort by timestamp
        _deviceDataHistory[deviceId]!
            .sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Limit data points
        if (_deviceDataHistory[deviceId]!.length > MAX_DATA_POINTS) {
          _deviceDataHistory[deviceId] = _deviceDataHistory[deviceId]!
              .sublist(_deviceDataHistory[deviceId]!.length - MAX_DATA_POINTS);
        }
      }
    }

    // Clean up history for devices not in current readings (optional)
    final currentDevices = readings.map((r) => r.deviceId).toSet();
    _deviceDataHistory
        .removeWhere((deviceId, _) => !currentDevices.contains(deviceId));
  }

  List<DropdownMenuItem<String>> _getDeviceOptions(
      List<SensorReading> readings) {
    // FIXED: Get unique devices properly to avoid duplicate dropdown values
    final Set<String> uniqueDevices = readings.map((r) => r.deviceId).toSet();
    final List<String> sortedDevices = uniqueDevices.toList()..sort();

    return [
      DropdownMenuItem(value: 'All', child: Text('All Devices')),
      ...sortedDevices.map((device) => DropdownMenuItem(
            value: device,
            child: Text(
              device,
              overflow: TextOverflow.ellipsis,
            ),
          )),
    ];
  }

  Widget _buildBarChart(List<SensorReading> readings) {
    // Get latest reading per device for bar chart
    final Map<String, SensorReading> latestPerDevice = {};

    for (final reading in readings) {
      if (!latestPerDevice.containsKey(reading.deviceId) ||
          latestPerDevice[reading.deviceId]!.timestamp < reading.timestamp) {
        latestPerDevice[reading.deviceId] = reading;
      }
    }

    final sortedDevices = latestPerDevice.keys.toList()..sort();

    if (sortedDevices.isEmpty) {
      return Center(
        child: Text(
          'No device data available',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    // Calculate dynamic width based on number of devices
    final deviceCount = sortedDevices.length;
    final minBarWidth = 60.0; // Minimum width per bar for comfortable spacing
    final totalWidth = deviceCount * minBarWidth;
    final unit = _showTemperature ? '°C' : '%';

    return Column(
      children: [
        // Scroll indicator if needed
        if (deviceCount > 6) // Show indicator if more than 6 devices
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swipe_left, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Geser untuk melihat semua dari ${deviceCount} devices',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.swipe_right, size: 14, color: Colors.grey[600]),
              ],
            ),
          ),

        // Scrollable bar chart
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: AlwaysScrollableScrollPhysics(),
            child: Container(
              width: totalWidth < 300
                  ? 300
                  : totalWidth, // Minimum width for chart
              child: _buildScrollableBarChart(
                  sortedDevices, latestPerDevice, unit),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableBarChart(List<String> sortedDevices,
      Map<String, SensorReading> latestPerDevice, String unit) {
    final barGroups = sortedDevices.asMap().entries.map((entry) {
      final index = entry.key;
      final deviceId = entry.value;
      final reading = latestPerDevice[deviceId]!;
      final value = _showTemperature ? reading.temperature : reading.humidity;
      final color = _showTemperature ? Colors.red : Colors.blue;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: color,
            width: 24, // Increased bar width for better visibility
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _showTemperature ? 50 : 100,
              color: color.withOpacity(0.1),
            ),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly, // Better spacing
        maxY: _showTemperature ? 50 : 100,
        minY: 0,
        barGroups: barGroups,
        groupsSpace: 20, // Space between bars
        gridData: FlGridData(
          show: true,
          horizontalInterval: _showTemperature ? 10 : 20,
          drawVerticalLine:
              false, // Remove vertical grid lines for cleaner look
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedDevices.length) {
                  final deviceId = sortedDevices[index];
                  final displayName = deviceId.replaceAll('sensor_', '');
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }
                return Text('');
              },
              reservedSize: 35,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _showTemperature ? 10 : 20,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}$unit',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
            tooltipRoundedRadius: 8,
            tooltipPadding: EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex >= 0 && groupIndex < sortedDevices.length) {
                final deviceId = sortedDevices[groupIndex];
                final reading = latestPerDevice[deviceId]!;
                final value =
                    _showTemperature ? reading.temperature : reading.humidity;
                return BarTooltipItem(
                  '$deviceId\n${reading.displayTime}\n${value.toStringAsFixed(1)}$unit',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<SensorReading> readings) {
    if (readings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 48, color: Colors.grey[400]),
            SizedBox(height: 8),
            Text(
              'No data for $_selectedDevice',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Text(
              'Data will appear as readings come in',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    final spots = _createSpots(readings);
    final lineColor = _showTemperature ? Colors.red : Colors.blue;
    final unit = _showTemperature ? '°C' : '%';

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _showTemperature ? 5 : 10,
          verticalInterval:
              spots.length > 10 ? (spots.length / 5).round().toDouble() : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval:
                  spots.length > 10 ? (spots.length / 5).round().toDouble() : 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < readings.length) {
                  final reading = readings[index];
                  final time = reading.displayTime.split(':');
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${time[0]}:${time[1]}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _showTemperature ? 5 : 10,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}$unit',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        minX: 0,
        maxX: (readings.length - 1).toDouble(),
        minY: _getMinY(readings),
        maxY: _getMaxY(readings),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length <= 20,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: lineColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                if (index >= 0 && index < readings.length) {
                  final reading = readings[index];
                  final value =
                      _showTemperature ? reading.temperature : reading.humidity;
                  return LineTooltipItem(
                    '${reading.deviceId}\n${reading.displayTime}\n${value.toStringAsFixed(1)}$unit\nTotal: ${readings.length} points',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<FlSpot> _createSpots(List<SensorReading> readings) {
    return readings.asMap().entries.map((entry) {
      final index = entry.key;
      final reading = entry.value;
      final value = _showTemperature ? reading.temperature : reading.humidity;
      return FlSpot(index.toDouble(), value);
    }).toList();
  }

  double _getMinY(List<SensorReading> readings) {
    if (readings.isEmpty) return 0;
    final values = readings
        .map((r) => _showTemperature ? r.temperature : r.humidity)
        .toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final padding = _showTemperature ? 5 : 10;
    return (min - padding).clamp(0, double.infinity);
  }

  double _getMaxY(List<SensorReading> readings) {
    if (readings.isEmpty) return 100;
    final values = readings
        .map((r) => _showTemperature ? r.temperature : r.humidity)
        .toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    final padding = _showTemperature ? 5 : 10;
    return max + padding;
  }

  @override
  void dispose() {
    // Clear device data history when widget is disposed
    _deviceDataHistory.clear();
    super.dispose();
  }
}
