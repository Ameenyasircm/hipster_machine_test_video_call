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
  StreamCallback onRemoteStream;
  SimpleCallback onCallEnded;
  CallIdCallback onIncomingCall;
  CallStatusCallback onCallStatusChanged;

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
// The peerConnection must be created and set to _peerConnection before this function is called.

  Future<void> initializeMedia() async {
    try {
      print('CALL SERVICE: Requesting media access...');

      // Request camera and microphone access using flutter_webrtc
      // Use the static MediaDevices from the flutter_webrtc package
      localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

      if (localStream != null) {
        print('CALL SERVICE: Local media stream retrieved successfully.');

        // 3. Add tracks to the RTCPeerConnection (Crucial next step in WebRTC)
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
      // Configuration for STUN/TURN servers (use your own in production)
      final Map<String, dynamic> configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          // Add TURN servers here for production
        ],
        'sdpSemantics': 'unified-plan',
      };

      // Use the WebRTC library's createPeerConnection (note the capital P)
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
        // In real implementation, send this to the other peer via signaling
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

      // Ensure media is initialized
      if (localStream == null) {
        await initializeMedia();
      }

      // Create peer connection
      await _createPeerConnection();

      // Create and send offer (in real app, send via signaling server)
      RTCSessionDescription offer = await peerConnection!.createOffer();
      await peerConnection!.setLocalDescription(offer);

      print('CALL SERVICE: Offer created and set as local description');

      // TODO: Send offer to target user via your signaling mechanism
      // await _signalingServer.sendOffer(targetId, offer);

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

      // Ensure media is initialized
      if (localStream == null) {
        await initializeMedia();
      }

      // Create peer connection
      await _createPeerConnection();

      // TODO: In real implementation:
      // 1. Receive offer from caller via signaling
      // 2. Set remote description with the offer
      // 3. Create answer
      // 4. Set local description with the answer
      // 5. Send answer back to caller

      // Example:
      // await peerConnection!.setRemoteDescription(receivedOffer);
      // RTCSessionDescription answer = await peerConnection!.createAnswer();
      // await peerConnection!.setLocalDescription(answer);
      // await _signalingServer.sendAnswer(callerId, answer);

      print('CALL SERVICE: Call accepted, waiting for connection...');
    } catch (e) {
      print('CALL SERVICE ERROR: Failed to accept call: $e');
      onCallStatusChanged('error');
      rethrow;
    }
  }

  /// End the current call
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

    // TODO: Connect to your signaling server and listen for incoming calls
    // Example using websocket or Firebase:
    // _signalingServer.onIncomingCall.listen((callData) {
    //   currentCallId = callData.callId;
    //   onIncomingCall(callData.callId);
    // });
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

  /// Clean up resources
  void _cleanup() {
    // Close peer connection
    peerConnection?.close();
    peerConnection = null;

    // Note: Don't dispose localStream here if you want to reuse it
    // Only dispose on final cleanup in dispose()
    remoteStream = null;
  }

  /// Dispose and clean up all resources
  void dispose() {
    print('CALL SERVICE: Disposing SignalingService');

    _cleanup();

    // Dispose media streams
    localStream?.getTracks().forEach((track) {
      track.stop();
    });
    localStream?.dispose();
    localStream = null;

    remoteStream?.dispose();
    remoteStream = null;

    print('CALL SERVICE: SignalingService disposed');
  }
}