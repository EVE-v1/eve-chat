import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/webrtc_service.dart';
import '../services/nearby_service.dart';
import '../models/message_model.dart' as msg;

class CallScreen extends StatefulWidget {
  final String deviceName;
  final bool isVideo;
  final bool isCaller;

  const CallScreen({
    super.key,
    required this.deviceName,
    required this.isVideo,
    required this.isCaller,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final WebRTCService _webrtcService = WebRTCService();
  final NearbyService _nearbyService = NearbyService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    // Request permissions
    if (widget.isVideo) {
      await Permission.camera.request();
    }
    await Permission.microphone.request();

    // Initialize renderers
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    // Initialize WebRTC
    await _webrtcService.initializeCall(
      isVideo: widget.isVideo,
      isCaller: widget.isCaller,
    );

    // Set local stream
    if (_webrtcService.localStream != null) {
      _localRenderer.srcObject = _webrtcService.localStream;
    }

    // Listen for remote stream
    _webrtcService.remoteStream.listen((stream) {
      if (mounted) {
        setState(() {
          _remoteRenderer.srcObject = stream;
        });
      }
    });

    // Listen for call state
    _webrtcService.callState.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
        if (!connected) {
          Navigator.pop(context);
        }
      }
    });

    // Listen for signaling messages from nearby service
    _nearbyService.signalingMessages.listen((message) {
      msg.MessageType type = message['type'];
      Map<String, dynamic> data = message['data'];
      _webrtcService.handleSignalingMessage(type, data);
    });
  }

  Future<void> _toggleMute() async {
    await _webrtcService.toggleMute();
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  Future<void> _toggleCamera() async {
    if (widget.isVideo) {
      await _webrtcService.toggleCamera();
      setState(() {
        _isCameraOff = !_isCameraOff;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (widget.isVideo) {
      await _webrtcService.switchCamera();
    }
  }

  Future<void> _endCall() async {
    await _webrtcService.endCall();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen)
            if (widget.isVideo)
              Positioned.fill(
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),

            // Local video (small preview in corner)
            if (widget.isVideo)
              Positioned(
                top: 40,
                right: 20,
                width: 120,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),

            // Top bar with device name
            Positioned(
              top: 20,
              left: 20,
              right: widget.isVideo ? 160 : 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.deviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isConnected ? 'Connected' : 'Connecting...',
                      style: TextStyle(
                        color: _isConnected ? Colors.green : Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onPressed: _toggleMute,
                    backgroundColor: _isMuted ? Colors.red : Colors.grey[800]!,
                  ),

                  // Camera toggle (video calls only)
                  if (widget.isVideo)
                    _buildControlButton(
                      icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                      onPressed: _toggleCamera,
                      backgroundColor: _isCameraOff
                          ? Colors.red
                          : Colors.grey[800]!,
                    ),

                  // Switch camera (video calls only)
                  if (widget.isVideo)
                    _buildControlButton(
                      icon: Icons.flip_camera_android,
                      onPressed: _switchCamera,
                      backgroundColor: Colors.grey[800]!,
                    ),

                  // End call button
                  _buildControlButton(
                    icon: Icons.call_end,
                    onPressed: _endCall,
                    backgroundColor: Colors.red,
                    size: 64,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    double size = 56,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        iconSize: size * 0.5,
      ),
    );
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }
}
