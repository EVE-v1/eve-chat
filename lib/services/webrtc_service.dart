import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/message_model.dart' as msg;
import 'nearby_service.dart';

class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  final NearbyService _nearbyService = NearbyService();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final StreamController<MediaStream> _remoteStreamController =
      StreamController.broadcast();
  final StreamController<bool> _callStateController =
      StreamController.broadcast();

  Stream<MediaStream> get remoteStream => _remoteStreamController.stream;
  Stream<bool> get callState => _callStateController.stream;

  bool _isVideoCall = false;

  // WebRTC configuration for peer-to-peer without STUN/TURN servers
  final Map<String, dynamic> _configuration = {
    'iceServers': [], // Empty for local P2P
    'sdpSemantics': 'unified-plan',
  };

  final Map<String, dynamic> _constraints = {'mandatory': {}, 'optional': []};

  Future<void> initializeCall({
    required bool isVideo,
    required bool isCaller,
  }) async {
    _isVideoCall = isVideo;

    // Get user media
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': isVideo
          ? {'facingMode': 'user', 'width': 640, 'height': 480}
          : false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(
        mediaConstraints,
      );

      // Create peer connection
      _peerConnection = await createPeerConnection(
        _configuration,
        _constraints,
      );

      // Add local stream to peer connection
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // Handle remote stream
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          _remoteStreamController.add(_remoteStream!);
        }
      };

      // Handle ICE candidates
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate != null) {
          _sendSignalingMessage(msg.MessageType.candidate, {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          });
        }
      };

      // Handle connection state
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _callStateController.add(true);
        } else if (state ==
                RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          _callStateController.add(false);
        }
      };

      if (isCaller) {
        await _createOffer();
      }
    } catch (e) {
      // Error initializing call
      rethrow;
    }
  }

  Future<void> _createOffer() async {
    try {
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      _sendSignalingMessage(msg.MessageType.offer, {
        'sdp': offer.sdp,
        'type': offer.type,
      });
    } catch (e) {
      // Error creating offer
    }
  }

  Future<void> handleSignalingMessage(
    msg.MessageType type,
    Map<String, dynamic> data,
  ) async {
    try {
      switch (type) {
        case msg.MessageType.offer:
          await _handleOffer(data);
          break;
        case msg.MessageType.answer:
          await _handleAnswer(data);
          break;
        case msg.MessageType.candidate:
          await _handleCandidate(data);
          break;
        default:
          break;
      }
    } catch (e) {
      // Error handling signaling message
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    RTCSessionDescription offer = RTCSessionDescription(
      data['sdp'],
      data['type'],
    );

    await _peerConnection!.setRemoteDescription(offer);

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _sendSignalingMessage(msg.MessageType.answer, {
      'sdp': answer.sdp,
      'type': answer.type,
    });
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    RTCSessionDescription answer = RTCSessionDescription(
      data['sdp'],
      data['type'],
    );

    await _peerConnection!.setRemoteDescription(answer);
  }

  Future<void> _handleCandidate(Map<String, dynamic> data) async {
    RTCIceCandidate candidate = RTCIceCandidate(
      data['candidate'],
      data['sdpMid'],
      data['sdpMLineIndex'],
    );

    await _peerConnection!.addCandidate(candidate);
  }

  void _sendSignalingMessage(msg.MessageType type, Map<String, dynamic> data) {
    _nearbyService.sendMessage(jsonEncode(data), type: type);
  }

  MediaStream? get localStream => _localStream;

  Future<void> toggleMute() async {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        final enabled = audioTracks[0].enabled;
        audioTracks[0].enabled = !enabled;
      }
    }
  }

  Future<void> toggleCamera() async {
    if (_localStream != null && _isVideoCall) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        final enabled = videoTracks[0].enabled;
        videoTracks[0].enabled = !enabled;
      }
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null && _isVideoCall) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await Helper.switchCamera(videoTracks[0]);
      }
    }
  }

  Future<void> endCall() async {
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    await _peerConnection?.close();

    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;

    _callStateController.add(false);
  }

  void dispose() {
    _remoteStreamController.close();
    _callStateController.close();
  }
}
