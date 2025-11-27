import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import '../models/message_model.dart';

class NearbyService {
  static final NearbyService _instance = NearbyService._internal();
  factory NearbyService() => _instance;
  NearbyService._internal();

  final Nearby _nearby = Nearby();
  final StreamController<List<String>> _devicesController =
      StreamController.broadcast();
  final StreamController<MessageModel> _messageController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _connectionStatusController =
      StreamController.broadcast();

  Stream<List<String>> get discoveredDevices => _devicesController.stream;
  Stream<MessageModel> get messages => _messageController.stream;
  Stream<Map<String, dynamic>> get connectionStatus =>
      _connectionStatusController.stream;

  final Map<String, String> _discoveredDevices = {}; // endpointId -> name
  String? _connectedEndpoint;
  String? _connectedDeviceName;
  String? _myName;

  Future<void> startAdvertising(String userName) async {
    _myName = userName;

    await _nearby.startAdvertising(
      userName,
      Strategy.P2P_CLUSTER,
      onConnectionInitiated: _onConnectionInit,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
    );
  }

  Future<void> startDiscovery() async {
    _discoveredDevices.clear();

    await _nearby.startDiscovery(
      _myName ?? 'Eve User',
      Strategy.P2P_CLUSTER,
      onEndpointFound: (endpointId, name, serviceId) {
        _discoveredDevices[endpointId] = name;
        _devicesController.add(_discoveredDevices.values.toList());
      },
      onEndpointLost: (endpointId) {
        _discoveredDevices.remove(endpointId);
        _devicesController.add(_discoveredDevices.values.toList());
      },
    );
  }

  Future<void> connectToDevice(String deviceName) async {
    String? endpointId = _discoveredDevices.entries
        .firstWhere(
          (entry) => entry.value == deviceName,
          orElse: () => MapEntry('', ''),
        )
        .key;

    if (endpointId.isNotEmpty) {
      _connectedDeviceName = deviceName;
      await _nearby.requestConnection(
        _myName ?? 'Eve User',
        endpointId,
        onConnectionInitiated: _onConnectionInit,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    }
  }

  void _onConnectionInit(String endpointId, ConnectionInfo info) {
    // Store the device name from connection info
    if (_connectedDeviceName == null) {
      _connectedDeviceName = info.endpointName;
    }

    // Auto-accept connection
    _nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved: (endpointId, payload) async {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          try {
            String jsonStr = String.fromCharCodes(payload.bytes!);
            Map<String, dynamic> data = jsonDecode(jsonStr);

            String messageId = DateTime.now().millisecondsSinceEpoch.toString();
            String text = data['content'] ?? '';
            MessageType type = MessageType.values.firstWhere(
              (e) => e.toString() == data['type'],
              orElse: () => MessageType.text,
            );

            String? audioPath;
            Duration? audioDuration;

            if (type == MessageType.audio && data['audioData'] != null) {
              // Save audio bytes to file
              final bytes = base64Decode(data['audioData']);
              final dir = await getTemporaryDirectory();
              final file = File('${dir.path}/audio_$messageId.m4a');
              await file.writeAsBytes(bytes);
              audioPath = file.path;
              text = 'Voice Message';
            }

            _messageController.add(
              MessageModel(
                id: messageId,
                senderId: endpointId,
                text: text,
                timestamp: DateTime.now(),
                isSent: false,
                type: type,
                audioPath: audioPath,
                audioDuration: audioDuration,
              ),
            );
          } catch (e) {
            // Fallback for old plain text messages
            String message = String.fromCharCodes(payload.bytes!);
            _messageController.add(
              MessageModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                senderId: endpointId,
                text: message,
                timestamp: DateTime.now(),
                isSent: false,
              ),
            );
          }
        }
      },
    );
  }

  void _onConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      _connectedEndpoint = endpointId;
      stopDiscovery();
      stopAdvertising();

      // Notify listeners about connection
      _connectionStatusController.add({
        'connected': true,
        'deviceName': _connectedDeviceName ?? 'Unknown Device',
      });
    }
  }

  void _onDisconnected(String endpointId) {
    _connectedEndpoint = null;
  }

  Future<void> sendMessage(
    String content, {
    MessageType type = MessageType.text,
    String? audioPath,
  }) async {
    if (_connectedEndpoint != null) {
      Map<String, dynamic> payload = {
        'type': type.toString(),
        'content': content,
      };

      if (type == MessageType.audio && audioPath != null) {
        File file = File(audioPath);
        if (await file.exists()) {
          List<int> bytes = await file.readAsBytes();
          payload['audioData'] = base64Encode(bytes);
        }
      }

      String jsonStr = jsonEncode(payload);

      await _nearby.sendBytesPayload(
        _connectedEndpoint!,
        Uint8List.fromList(jsonStr.codeUnits),
      );
    }
  }

  Future<void> stopDiscovery() async {
    await _nearby.stopDiscovery();
  }

  Future<void> stopAdvertising() async {
    await _nearby.stopAdvertising();
  }

  Future<void> disconnect() async {
    if (_connectedEndpoint != null) {
      await _nearby.disconnectFromEndpoint(_connectedEndpoint!);
      _connectedEndpoint = null;
    }
  }

  bool get isConnected => _connectedEndpoint != null;

  void dispose() {
    _devicesController.close();
    _messageController.close();
    _connectionStatusController.close();
  }
}
