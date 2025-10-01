// lib/features/auth/presentation/pages/video_call_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class VideoCallingScreen extends StatefulWidget {
  final String loginUserId;
  final String channelName;
  final String targetUserName;
  final bool isCaller;

  const VideoCallingScreen({
    Key? key,
    required this.loginUserId,
    required this.channelName,
    required this.targetUserName,
    required this.isCaller,
  }) : super(key: key);

  @override
  State<VideoCallingScreen> createState() => _VideoCallingScreenState();
}

class _VideoCallingScreenState extends State<VideoCallingScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  bool _inCall = false;
  bool _isConnecting = false;
  bool _remoteDescriptionSet = false;

  // Control states
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;

  final List<RTCIceCandidate> _remoteCandidatesQueue = [];
  StreamSubscription? _offerSubscription;
  StreamSubscription? _answerSubscription;
  StreamSubscription? _candidateSubscription;
  StreamSubscription? _callStatusSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  Future<void> _cleanup() async {
    // Cancel all subscriptions
    await _offerSubscription?.cancel();
    await _answerSubscription?.cancel();
    await _candidateSubscription?.cancel();
    await _callStatusSubscription?.cancel();

    // Stop local stream
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();

    // Close peer connection
    await _peerConnection?.close();

    // Dispose renderers
    await _localRenderer.dispose();
    await _remoteRenderer.dispose();
  }

  Future<void> _initializeCall() async {
    setState(() => _isConnecting = true);

    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _initLocalStream();
    await _createPeerConnection();

    // Listen for call status changes
    _listenToCallStatus();

    if (widget.isCaller) {
      // CALLER: Create and send offer
      await _createAndSendOffer();
      // Listen for answer from receiver
      _listenForAnswer();
    } else {
      // RECEIVER: Listen for offer from caller
      _listenForOffer();
    }

    // Both listen for ICE candidates
    _listenForIceCandidates();
  }

  // WebRTC Configuration
  Map<String, dynamic> get _configuration => {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  Map<String, dynamic> get _constraints => {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  Map<String, dynamic> get _mediaConstraints => {
    'audio': true,
    'video': {
      'mandatory': {
        'minWidth': '640',
        'minHeight': '480',
        'minFrameRate': '30',
      },
      'facingMode': 'user',
      'optional': [],
    }
  };

  // Initialize local media stream
  Future<void> _initLocalStream() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);
      _localRenderer.srcObject = _localStream;
      setState(() {});
    } catch (e) {
      print('Error getting user media: $e');
      _showError('Failed to access camera/microphone');
    }
  }

  // Create peer connection
  Future<void> _createPeerConnection() async {
    try {
      _peerConnection = await createPeerConnection(_configuration, _constraints);

      // Add local stream tracks
      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });

      // Handle ICE candidates
      _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        print('Generated ICE candidate');
        _sendIceCandidate(candidate);
      };

      // Handle remote stream
      _peerConnection?.onTrack = (RTCTrackEvent event) {
        print('Received remote track: ${event.track.kind}');
        if (event.streams.isNotEmpty) {
          setState(() {
            _remoteRenderer.srcObject = event.streams[0];
          });
        }
      };

      // Handle connection state changes
      _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
        print('Connection state: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          setState(() {
            _inCall = true;
            _isConnecting = false;
          });
          // Update call status in Firestore
          _updateCallStatus('connected');
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          _handleCallEnd();
        }
      };

      _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
        print('ICE connection state: $state');
      };

      _peerConnection?.onSignalingState = (RTCSignalingState state) {
        print('Signaling state: $state');
      };
    } catch (e) {
      print('Error creating peer connection: $e');
      _showError('Failed to create connection');
    }
  }

  // ============================================
  // CALLER METHODS
  // ============================================

  Future<void> _createAndSendOffer() async {
    if (_peerConnection == null) return;

    try {
      print('Creating offer...');
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // Save offer to Firestore
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.channelName)
          .collection('signaling')
          .doc('offer')
          .set({
        'type': 'offer',
        'sdp': offer.sdp,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Offer sent successfully');
    } catch (e) {
      print('Error creating offer: $e');
      _showError('Failed to create call');
    }
  }

  void _listenForAnswer() {
    _answerSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.channelName)
        .collection('signaling')
        .doc('answer')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        if (data['type'] == 'answer' && data['sdp'] != null) {
          print('Received answer from receiver');
          _handleRemoteAnswer(RTCSessionDescription(data['sdp'], 'answer'));
        }
      }
    });
  }

  Future<void> _handleRemoteAnswer(RTCSessionDescription answer) async {
    if (_peerConnection == null || _remoteDescriptionSet) return;

    try {
      await _peerConnection!.setRemoteDescription(answer);
      _remoteDescriptionSet = true;
      print('Remote answer set successfully');

      // Process queued ICE candidates
      for (var candidate in _remoteCandidatesQueue) {
        await _peerConnection!.addCandidate(candidate);
      }
      _remoteCandidatesQueue.clear();
    } catch (e) {
      print('Error handling remote answer: $e');
    }
  }

  // ============================================
  // RECEIVER METHODS
  // ============================================

  void _listenForOffer() {
    _offerSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.channelName)
        .collection('signaling')
        .doc('offer')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        if (data['type'] == 'offer' && data['sdp'] != null) {
          print('Received offer from caller');
          _handleRemoteOffer(RTCSessionDescription(data['sdp'], 'offer'));
        }
      }
    });
  }

  Future<void> _handleRemoteOffer(RTCSessionDescription offer) async {
    if (_peerConnection == null || _remoteDescriptionSet) return;

    try {
      // Check current signaling state
      final signalingState = await _peerConnection!.getSignalingState();
      print('Current signaling state: $signalingState');

      // Prevent setting remote offer if already have local offer
      if (signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        print('ERROR: Already in have-local-offer state! Resetting...');
        await _resetConnection();
        return;
      }

      // Set remote description (the offer)
      await _peerConnection!.setRemoteDescription(offer);
      _remoteDescriptionSet = true;
      print('Remote offer set successfully');

      // Process queued ICE candidates
      for (var candidate in _remoteCandidatesQueue) {
        await _peerConnection!.addCandidate(candidate);
      }
      _remoteCandidatesQueue.clear();

      // Create and send answer
      await _createAndSendAnswer();
    } catch (e) {
      print('Error handling remote offer: $e');
      _showError('Failed to establish connection');
    }
  }

  Future<void> _createAndSendAnswer() async {
    if (_peerConnection == null) return;

    try {
      print('Creating answer...');
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Save answer to Firestore
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.channelName)
          .collection('signaling')
          .doc('answer')
          .set({
        'type': 'answer',
        'sdp': answer.sdp,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Answer sent successfully');

      // Update call status to accepted
      _updateCallStatus('accepted');
    } catch (e) {
      print('Error creating answer: $e');
      _showError('Failed to answer call');
    }
  }

  // ============================================
  // ICE CANDIDATE HANDLING
  // ============================================

  void _sendIceCandidate(RTCIceCandidate candidate) {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.channelName)
        .collection('candidates')
        .add({
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
      'senderId': widget.loginUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _listenForIceCandidates() {
    _candidateSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.channelName)
        .collection('candidates')
        .where('senderId', isNotEqualTo: widget.loginUserId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final candidate = RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            );
            _handleRemoteIceCandidate(candidate);
          }
        }
      }
    });
  }

  Future<void> _handleRemoteIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) return;

    try {
      // Queue candidates if remote description not set yet
      if (!_remoteDescriptionSet) {
        print('Queueing ICE candidate');
        _remoteCandidatesQueue.add(candidate);
        return;
      }

      await _peerConnection!.addCandidate(candidate);
      print('Added remote ICE candidate');
    } catch (e) {
      print('Error adding ICE candidate: $e');
    }
  }

  // ============================================
  // CALL STATUS & CLEANUP
  // ============================================

  void _listenToCallStatus() {
    _callStatusSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.channelName)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final status = snapshot.data()?['status'];
        if (status == 'ended' && mounted) {
          _handleCallEnd();
        }
      }
    });
  }

  Future<void> _updateCallStatus(String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.channelName)
          .update({'status': status});
    } catch (e) {
      print('Error updating call status: $e');
    }
  }

  Future<void> _resetConnection() async {
    await _peerConnection?.close();
    _remoteDescriptionSet = false;
    _remoteCandidatesQueue.clear();
    await _createPeerConnection();
  }

  void _handleCallEnd() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _endCall() async {
    await _updateCallStatus('ended');

    // Delete call signaling data
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.channelName)
        .collection('signaling')
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    });

    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.channelName)
        .collection('candidates')
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    });

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ============================================
  // MEDIA CONTROLS
  // ============================================

  Future<void> _toggleMute() async {
    if (_localStream == null) return;

    setState(() {
      _isMuted = !_isMuted;
    });

    _localStream!.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
  }

  Future<void> _toggleVideo() async {
    if (_localStream == null) return;

    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });

    _localStream!.getVideoTracks().forEach((track) {
      track.enabled = _isVideoEnabled;
    });
  }

  Future<void> _switchCamera() async {
    if (_localStream == null) return;

    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });

    final videoTrack = _localStream!.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
    }
  }

  // ============================================
  // UI
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen)
            Center(
              child: _remoteRenderer.srcObject != null
                  ? RTCVideoView(_remoteRenderer, mirror: false, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                  : Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isConnecting) ...[
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 20),
                        Text(
                          widget.isCaller ? 'Calling ${widget.targetUserName}...' : 'Connecting...',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ] else ...[
                        Icon(Icons.person, size: 80, color: Colors.white54),
                        SizedBox(height: 20),
                        Text(
                          widget.targetUserName,
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Local video (small overlay)
            Positioned(
              top: 40,
              right: 20,
              width: 120,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _localRenderer.srcObject != null
                      ? RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                      : Container(color: Colors.grey[800]),
                ),
              ),
            ),

            // Top bar with call info
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.targetUserName,
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      _inCall ? 'Connected' : (_isConnecting ? 'Connecting...' : 'Ringing...'),
                      style: TextStyle(color: Colors.white70, fontSize: 14),
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
                  // Mute/Unmute button
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onTap: _toggleMute,
                    backgroundColor: _isMuted ? Colors.white : Colors.white24,
                    iconColor: _isMuted ? Colors.red : Colors.white,
                  ),

                  // End call button
                  GestureDetector(
                    onTap: _endCall,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.call_end, color: Colors.white, size: 35),
                    ),
                  ),

                  // Camera on/off button
                  _buildControlButton(
                    icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                    onTap: _toggleVideo,
                    backgroundColor: _isVideoEnabled ? Colors.white24 : Colors.white,
                    iconColor: _isVideoEnabled ? Colors.white : Colors.red,
                  ),
                ],
              ),
            ),

            // Camera flip button
            if (_isVideoEnabled)
              Positioned(
                bottom: 140,
                right: 30,
                child: _buildControlButton(
                  icon: Icons.flip_camera_ios,
                  onTap: _switchCamera,
                  backgroundColor: Colors.white24,
                  iconColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}