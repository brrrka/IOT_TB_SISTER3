import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mqtt_provider.dart';

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
