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
                      'Live Raw Data Stream',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
                    return _buildRawReadingItem(reading);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRawReadingItem(SensorReading reading) {
    // Status warna berdasarkan source saja, bukan anomali
    final statusColor = _getSourceColor(reading.source);

    return ListTile(
      dense: true,
      leading: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: reading.isHardware ? Colors.green[100] : Colors.purple[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          reading.isHardware ? Icons.memory : Icons.computer,
          size: 16,
          color: reading.isHardware ? Colors.green[800] : Colors.purple[800],
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
          ),
          SizedBox(width: 4),
          // Status badge untuk raw data
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'RAW',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        '${reading.temperature.toStringAsFixed(1)}°C • ${reading.humidity.toStringAsFixed(1)}% • ${reading.displayTime}',
        style: TextStyle(fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Data quality indicator
          Icon(
            _isDataValid(reading) ? Icons.check_circle : Icons.warning,
            color: _isDataValid(reading) ? Colors.green : Colors.orange,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            '#${reading.msgCount}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'hardware':
        return Colors.green;
      case 'simulation':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  bool _isDataValid(SensorReading reading) {
    // Basic data validation (not anomaly detection)
    return reading.temperature >= -50 &&
        reading.temperature <= 100 &&
        reading.humidity >= 0 &&
        reading.humidity <= 100;
  }
}
