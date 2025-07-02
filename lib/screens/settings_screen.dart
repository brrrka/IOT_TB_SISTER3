import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/mqtt_provider.dart';
import '../providers/api_provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiUrlController = TextEditingController();
  bool _autoRefreshEnabled = true;
  int _refreshInterval = 30; // seconds
  bool _showNotifications = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiUrlController.text =
          prefs.getString('api_url') ?? 'http://192.168.1.100:8000';
      _autoRefreshEnabled = prefs.getBool('auto_refresh') ?? true;
      _refreshInterval = prefs.getInt('refresh_interval') ?? 30;
      _showNotifications = prefs.getBool('show_notifications') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_url', _apiUrlController.text);
    await prefs.setBool('auto_refresh', _autoRefreshEnabled);
    await prefs.setInt('refresh_interval', _refreshInterval);
    await prefs.setBool('show_notifications', _showNotifications);
    await prefs.setBool('dark_mode', _darkMode);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Settings
            _buildSection(
              'Connection Settings',
              Icons.settings_ethernet,
              [
                _buildConnectionStatus(),
                SizedBox(height: 16),
                _buildApiUrlSetting(),
                SizedBox(height: 16),
                _buildConnectionTest(),
              ],
            ),

            SizedBox(height: 24),

            // App Settings
            _buildSection(
              'App Settings',
              Icons.settings,
              [
                _buildAutoRefreshSetting(),
                _buildRefreshIntervalSetting(),
                _buildNotificationSetting(),
                _buildThemeSetting(),
              ],
            ),

            SizedBox(height: 24),

            // Data Management
            _buildSection(
              'Data Management',
              Icons.data_usage,
              [
                _buildDataActions(),
              ],
            ),

            SizedBox(height: 24),

            // About
            _buildSection(
              'About',
              Icons.info,
              [
                _buildAppInfo(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[800]),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer2<MqttProvider, ApiProvider>(
      builder: (context, mqtt, api, child) {
        return Column(
          children: [
            _buildStatusRow(
              'MQTT Connection',
              mqtt.isConnected,
              mqtt.isConnected ? 'Connected to HiveMQ Cloud' : 'Disconnected',
              onTap: mqtt.isConnected ? null : () => mqtt.connect(),
            ),
            SizedBox(height: 8),
            _buildStatusRow(
              'API Connection',
              api.error == null,
              api.error == null ? 'API server responding' : 'Connection issues',
              onTap: () => _testApiConnection(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusRow(String title, bool isConnected, String subtitle,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                isConnected ? Icons.check_circle : Icons.error,
                color: isConnected ? Colors.green[800] : Colors.red[800],
                size: 16,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
          ],
        ),
      ),
    );
  }

  Widget _buildApiUrlSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'API Server URL',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _apiUrlController,
          decoration: InputDecoration(
            hintText: 'http://192.168.1.100:8000',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.link),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Enter your server IP address and port',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildConnectionTest() {
    return Consumer<ApiProvider>(
      builder: (context, api, child) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _testApiConnection,
                icon: Icon(Icons.wifi_find),
                label: Text('Test API Connection'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.read<MqttProvider>().connect(),
                icon: Icon(Icons.refresh),
                label: Text('Reconnect MQTT'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAutoRefreshSetting() {
    return SwitchListTile(
      title: Text('Auto-refresh Data'),
      subtitle: Text('Automatically refresh data from server'),
      value: _autoRefreshEnabled,
      onChanged: (bool value) {
        setState(() {
          _autoRefreshEnabled = value;
        });

        final apiProvider = context.read<ApiProvider>();
        if (value) {
          apiProvider.startAutoRefresh(
              interval: Duration(seconds: _refreshInterval));
        } else {
          apiProvider.stopAutoRefresh();
        }
      },
    );
  }

  Widget _buildRefreshIntervalSetting() {
    return ListTile(
      title: Text('Refresh Interval'),
      subtitle: Text('${_refreshInterval} seconds'),
      trailing: DropdownButton<int>(
        value: _refreshInterval,
        items: [15, 30, 60, 120, 300].map((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text('${value}s'),
          );
        }).toList(),
        onChanged: _autoRefreshEnabled
            ? (int? value) {
                if (value != null) {
                  setState(() {
                    _refreshInterval = value;
                  });

                  if (_autoRefreshEnabled) {
                    final apiProvider = context.read<ApiProvider>();
                    apiProvider.startAutoRefresh(
                        interval: Duration(seconds: value));
                  }
                }
              }
            : null,
      ),
    );
  }

  Widget _buildNotificationSetting() {
    return SwitchListTile(
      title: Text('Anomaly Notifications'),
      subtitle: Text('Show notifications for sensor anomalies'),
      value: _showNotifications,
      onChanged: (bool value) {
        setState(() {
          _showNotifications = value;
        });
      },
    );
  }

  Widget _buildThemeSetting() {
    return SwitchListTile(
      title: Text('Dark Mode'),
      subtitle: Text('Use dark theme (restart required)'),
      value: _darkMode,
      onChanged: (bool value) {
        setState(() {
          _darkMode = value;
        });
      },
    );
  }

  Widget _buildDataActions() {
    return Consumer2<MqttProvider, ApiProvider>(
      builder: (context, mqtt, api, child) {
        return Column(
          children: [
            ListTile(
              title: Text('Clear Real-time Data'),
              subtitle: Text('Clear MQTT real-time readings cache'),
              leading: Icon(Icons.clear_all),
              trailing: Icon(Icons.chevron_right),
              onTap: () => _showClearDataDialog('realtime'),
            ),
            ListTile(
              title: Text('Clear API Cache'),
              subtitle: Text('Clear stored API data'),
              leading: Icon(Icons.cached),
              trailing: Icon(Icons.chevron_right),
              onTap: () => _showClearDataDialog('api'),
            ),
            ListTile(
              title: Text('Export Data'),
              subtitle: Text('Export current data to file'),
              leading: Icon(Icons.download),
              trailing: Icon(Icons.chevron_right),
              onTap: _exportData,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppInfo() {
    return Column(
      children: [
        ListTile(
          title: Text('App Version'),
          subtitle: Text('1.0.0'),
          leading: Icon(Icons.info),
        ),
        ListTile(
          title: Text('Build Date'),
          subtitle: Text('2024-12-30'),
          leading: Icon(Icons.calendar_today),
        ),
        ListTile(
          title: Text('Developer'),
          subtitle: Text('IoT Sensor Monitoring Team'),
          leading: Icon(Icons.code),
        ),
        ListTile(
          title: Text('Documentation'),
          subtitle: Text('View setup and usage guide'),
          leading: Icon(Icons.help),
          trailing: Icon(Icons.open_in_new),
          onTap: _showDocumentation,
        ),
      ],
    );
  }

  Future<void> _testApiConnection() async {
    final apiProvider = context.read<ApiProvider>();

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
            Text('Testing API connection...'),
          ],
        ),
      ),
    );

    final success = await apiProvider.testConnection();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(success
                ? 'API connection successful'
                : 'API connection failed'),
          ],
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _showClearDataDialog(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Data'),
        content: Text(type == 'realtime'
            ? 'This will clear all real-time MQTT data from memory. Are you sure?'
            : 'This will clear all cached API data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (type == 'realtime') {
                context.read<MqttProvider>().clearRealtimeData();
              } else {
                context.read<ApiProvider>().clearData();
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    // Implementation for data export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showDocumentation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Documentation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('IoT Sensor Monitoring App',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Features:'),
              Text('• Real-time MQTT data subscription'),
              Text('• REST API integration'),
              Text('• Device management'),
              Text('• Anomaly detection'),
              Text('• Environmental monitoring'),
              SizedBox(height: 16),
              Text('Setup:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('1. Ensure backend server is running'),
              Text('2. Update API URL in settings'),
              Text('3. Check network connectivity'),
              Text('4. Test connections'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
