// lib/core/utils/call_service.dart

import 'package:flutter_webrtc/flutter_webrtc.dart';
// Note: You must ensure 'flutter_webrtc' is installed in your project.

// Define a simple User model

class AppUser {
  final String id;
  final String name;
  final String phoneNumber; // <-- Added the new field
  final String email;
  final String fcmToken;

  AppUser({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.fcmToken,
  });

  // Factory constructor to create an AppUser from a Firestore document
  factory AppUser.fromFirestore(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] ?? 'N/A',
      phoneNumber: data['phoneNumber'] ?? 'N/A', // <-- Mapped the new field
      email: data['email'] ?? 'N/A',
      fcmToken: data['fcmToken'] ?? 'N/A',
    );
  }
}

// Define the function signatures for the callbacks
// In '../../../../core/utils/call_service.dart'


// Type definitions (use these if they are not in a separate file)
// lib/core/utils/call_service.dart


// lib/core/utils/call_service.dart


typedef StreamCallback = void Function(MediaStream stream);
typedef CallIdCallback = void Function(String callId);
typedef CallStatusCallback = void Function(String status);
typedef SimpleCallback = void Function();


class SignalingService {
  // Callbacks
  final StreamCallback onRemoteStream;
  final SimpleCallback onCallEnded;
  final CallIdCallback onIncomingCall;
  final CallStatusCallback onCallStatusChanged;

  // State variables
  MediaStream? localStream;
  MediaStream? remoteStream;
  RTCPeerConnection? peerConnection;
  String? currentCallId;
  String? targetUserId;

  // Media constraints
  final Map<String, dynamic> mediaConstraints = {
    'audio': true,
    'video': {
      'facingMode': 'user',
      'width': {'ideal': 1280},
      'height': {'ideal': 720},
    }
  };

  SignalingService({
    required this.onRemoteStream,
    required this.onCallEnded,
    required this.onIncomingCall,
    required this.onCallStatusChanged,
  }) {
    print('CALL SERVICE: SignalingService initialized');
  }

  /// Initialize local media stream (camera and microphone)
  Future<void> initializeMedia() async {
    try {
      print('CALL SERVICE: Requesting media access...');
      localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

      if (localStream != null) {
        print('CALL SERVICE: Local media stream retrieved successfully.');
        if (peerConnection != null) {
          localStream!.getTracks().forEach((track) {
            peerConnection!.addTrack(track, localStream!);
            print('CALL SERVICE: Added track ${track.kind} to peer connection.');
          });
        }
      } else {
        print('CALL SERVICE WARNING: Local stream is null after getUserMedia');
      }
    } catch (e) {
      print('CALL SERVICE ERROR: Failed to get user media: $e');
      localStream = null;
      rethrow;
    }
  }

  /// Create WebRTC peer connection
  Future<void> _createPeerConnection() async {
    try {
      final Map<String, dynamic> configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
        'sdpSemantics': 'unified-plan',
      };

      peerConnection = await createPeerConnection(configuration);

      // Add local stream tracks to peer connection
      if (localStream != null) {
        localStream!.getTracks().forEach((track) {
          peerConnection!.addTrack(track, localStream!);
        });
      }

      // Handle remote stream
      peerConnection!.onTrack = (RTCTrackEvent event) {
        print('CALL SERVICE: Remote track received');
        if (event.streams.isNotEmpty) {
          remoteStream = event.streams[0];
          onRemoteStream(remoteStream!);
        }
      };

      // Handle ICE candidates
      peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        print('CALL SERVICE: ICE candidate generated: ${candidate.candidate}');
      };

      // Handle connection state changes
      peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        print('CALL SERVICE: Connection state: $state');
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            onCallStatusChanged('active');
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            onCallStatusChanged('ended');
            onCallEnded();
            break;
          default:
            break;
        }
      };

      print('CALL SERVICE: Peer connection created successfully');
    } catch (e) {
      print('CALL SERVICE ERROR: Failed to create peer connection: $e');
      rethrow;
    }
  }

  /// Create call and send offer to target user
  Future<void> createCall(String targetId) async {
    try {
      targetUserId = targetId;
      currentCallId = 'call_${DateTime.now().millisecondsSinceEpoch}';
      print('CALL SERVICE: Creating call $currentCallId to $targetId');
      onCallStatusChanged('calling');

      if (localStream == null) await initializeMedia();
      await _createPeerConnection();

      RTCSessionDescription offer = await peerConnection!.createOffer();
      await peerConnection!.setLocalDescription(offer);
      print('CALL SERVICE: Offer created and set as local description');

      // TODO: Send offer to target via signaling server
    } catch (e) {
      print('CALL SERVICE ERROR: Failed to create call: $e');
      onCallStatusChanged('error');
      rethrow;
    }
  }

  /// Accept incoming call
  Future<void> acceptCall() async {
    try {
      print('CALL SERVICE: Accepting call $currentCallId');
      onCallStatusChanged('connecting');

      if (localStream == null) await initializeMedia();
      await _createPeerConnection();

      // TODO: Receive offer from caller, setRemoteDescription, create answer, send back
      print('CALL SERVICE: Call accepted, waiting for connection...');
    } catch (e) {
      print('CALL SERVICE ERROR: Failed to accept call: $e');
      onCallStatusChanged('error');
      rethrow;
    }
  }

  /// End current call
  void endCall() {
    print('CALL SERVICE: Ending call $currentCallId');
    _cleanup();
    onCallStatusChanged('ended');
    onCallEnded();
    currentCallId = null;
    targetUserId = null;
  }

  /// Reject incoming call
  void rejectCall() {
    print('CALL SERVICE: Rejecting call $currentCallId');
    _cleanup();
    onCallStatusChanged('rejected');
    currentCallId = null;
    targetUserId = null;
  }

  /// Listen for incoming calls
  void listenForIncomingCalls(String userId) {
    print('CALL SERVICE: Listening for incoming calls for user $userId');
    // TODO: Connect to signaling server and call onIncomingCall(callId)
  }

  /// Toggle microphone mute
  void toggleMute() {
    if (localStream != null) {
      final audioTracks = localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        bool enabled = audioTracks[0].enabled;
        audioTracks[0].enabled = !enabled;
        print('CALL SERVICE: Audio ${!enabled ? "muted" : "unmuted"}');
      }
    }
  }

  /// Toggle camera on/off
  void toggleCamera() {
    if (localStream != null) {
      final videoTracks = localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        bool enabled = videoTracks[0].enabled;
        videoTracks[0].enabled = !enabled;
        print('CALL SERVICE: Video ${!enabled ? "disabled" : "enabled"}');
      }
    }
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (localStream != null) {
      final videoTracks = localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await Helper.switchCamera(videoTracks[0]);
        print('CALL SERVICE: Camera switched');
      }
    }
  }

  /// Clean up peer connection and streams
  void _cleanup() {
    peerConnection?.close();
    peerConnection = null;
    remoteStream = null;
  }

  /// Dispose everything permanently
  void dispose() {
    print('CALL SERVICE: Disposing SignalingService');
    _cleanup();

    localStream?.getTracks().forEach((track) => track.stop());
    localStream?.dispose();
    localStream = null;

    remoteStream?.dispose();
    remoteStream = null;

    print('CALL SERVICE: SignalingService disposed');
  }
}
