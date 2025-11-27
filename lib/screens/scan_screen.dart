import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/nearby_service.dart';
import 'chat_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final NearbyService _nearbyService = NearbyService();
  final TextEditingController _nameController = TextEditingController(
    text: 'Eve User',
  );
  List<String> _devices = [];
  bool _isSearching = false;
  bool _isAdvertising = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();

    // Listen for connection events
    _nearbyService.connectionStatus.listen((status) {
      if (status['connected'] == true && mounted) {
        // If we are showing a loading state, clear it
        if (_isConnecting) {
          setState(() => _isConnecting = false);
        }

        String deviceName = status['deviceName'] ?? 'Unknown Device';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(deviceName: deviceName),
          ),
        );
      }
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetoothAdvertise.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.location.request();
    await Permission.nearbyWifiDevices.request();
  }

  Future<void> _startAdvertising() async {
    setState(() => _isAdvertising = true);
    await _nearbyService.startAdvertising(_nameController.text);
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isSearching = true;
      _devices.clear();
    });

    _nearbyService.discoveredDevices.listen((devices) {
      if (mounted) {
        setState(() => _devices = devices);
      }
    });

    await _nearbyService.startDiscovery();
  }

  Future<void> _connectToDevice(String deviceName) async {
    setState(() => _isConnecting = true);

    // Stop discovery before connecting to improve stability
    await _nearbyService.stopDiscovery();

    try {
      await _nearbyService.connectToDevice(deviceName);

      // Timeout safety
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isConnecting) {
          setState(() => _isConnecting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connection timed out. Try again.')),
          );
        }
      });
    } catch (e) {
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Eve Chat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Your Name',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAdvertising ? null : _startAdvertising,
                    icon: const Icon(Icons.wifi_tethering),
                    label: Text(
                      _isAdvertising ? 'Advertising...' : 'Make Discoverable',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(254, 113, 113, 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _startDiscovery,
                    icon: const Icon(Icons.search),
                    label: Text(_isSearching ? 'Searching...' : 'Find Devices'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(254, 113, 113, 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isSearching)
            const LinearProgressIndicator(
              color: Color.fromRGBO(254, 113, 113, 1),
              backgroundColor: Colors.grey,
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _isSearching
                  ? 'Found ${_devices.length} devices'
                  : 'Tap "Find Devices" to start',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ),
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No devices found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make sure both devices are searching\nand advertising',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final deviceName = _devices[index];
                      return Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.phone_android,
                            color: Color.fromRGBO(254, 113, 113, 1),
                          ),
                          title: Text(
                            deviceName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            _isConnecting ? 'Connecting...' : 'Tap to connect',
                            style: TextStyle(
                              color: _isConnecting
                                  ? const Color.fromRGBO(254, 113, 113, 1)
                                  : Colors.grey,
                            ),
                          ),
                          trailing: _isConnecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color.fromRGBO(254, 113, 113, 1),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                      254,
                                      113,
                                      113,
                                      1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'EVE CHAT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                          onTap: _isConnecting
                              ? null
                              : () => _connectToDevice(deviceName),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nearbyService.stopDiscovery();
    _nearbyService.stopAdvertising();
    super.dispose();
  }
}
