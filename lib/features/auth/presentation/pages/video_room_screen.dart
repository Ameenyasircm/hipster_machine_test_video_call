import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/signaling_service.dart';
import '../../../../core/constants/colors.dart';

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
    this.isCaller = true,
  }) : super(key: key);

  @override
  _VideoCallingScreenState createState() => _VideoCallingScreenState();
}

class _VideoCallingScreenState extends State<VideoCallingScreen> {
  SignalingService? _signalingService;
  late final RTCVideoRenderer _localRenderer;
  late final RTCVideoRenderer _remoteRenderer;
  bool _isInitialized = false;
  bool _hasRemoteStream = false;
  bool _isCallActive = true;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
  }

  Future<void> _initializeRenderers() async {
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();

    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _setupSignalingService();
  }

  void _setupSignalingService() {
    _signalingService = SignalingService(
      currentUserId: widget.loginUserId,
      channelName: widget.channelName,
      onAddRemoteStream: _handleRemoteStream,
      onCallEnded: _handleCallEnded,
    );

    _signalingService!.init().then((_) {
      setState(() {
        _isInitialized = true;
        _localRenderer.srcObject = _signalingService!.localStream;
      });

      if (widget.isCaller) {
        _signalingService!.createOffer();
      }
    }).catchError((error) {
      print('Error initializing call: $error');
      _showErrorDialog('Failed to initialize call');
    });
  }

  void _handleRemoteStream(MediaStream stream) {
    print('Remote stream received with ${stream.getTracks().length} tracks');
    if (mounted) {
      setState(() {
        _remoteRenderer.srcObject = stream;
        _hasRemoteStream = true;
      });
    }
  }

  void _handleCallEnded() {
    if (mounted) {
      setState(() {
        _isCallActive = false;
      });
      _showCallEndedDialog();
    }
  }

  void _showCallEndedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Call Ended'),
        content: const Text('The other party has ended the call.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _hangUp() async {
    await _signalingService?.hangUp();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _switchCamera() {
    final videoTrack = _signalingService?.localStream?.getVideoTracks().first;
    if (videoTrack != null) {
      Helper.switchCamera(videoTrack);
    }
  }

  void _toggleMute() {
    final audioTrack = _signalingService?.localStream?.getAudioTracks().first;
    if (audioTrack != null) {
      audioTrack.enabled = !audioTrack.enabled;
      setState(() {});
    }
  }

  bool get _isAudioMuted {
    final audioTrack = _signalingService?.localStream?.getAudioTracks().first;
    return audioTrack?.enabled == false;
  }

  @override
  void dispose() {
    _signalingService?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Call with ${widget.targetUserName}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: _hangUp,
          ),
        ],
      ),
      body: _isInitialized
          ? Stack(
        children: [
          // Remote video (full screen)
          Positioned.fill(
            child: _hasRemoteStream
                ? RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              mirror: false,
            )
                : Container(
              color: clDeepBlue,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: clLightSkyGray.withOpacity(0.3),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: clCleanWhite,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Connecting to ${widget.targetUserName}...',
                    style: TextStyle(
                      color: clCleanWhite,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  CircularProgressIndicator(color: accentColor),
                ],
              ),
            ),
          ),

          // Local video (pip)
          if (_localRenderer.srcObject != null)
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                width: 120,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: clCleanWhite, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: RTCVideoView(
                    _localRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    mirror: true,
                  ),
                ),
              ),
            ),

          // Call info
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.isCaller ? 'Calling ${widget.targetUserName}' : 'Incoming call',
                style: TextStyle(
                  color: clCleanWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute/Unmute
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _isAudioMuted ? Colors.red : clLightSkyGray.withOpacity(0.7),
                  child: IconButton(
                    onPressed: _toggleMute,
                    icon: Icon(
                      _isAudioMuted ? Icons.mic_off : Icons.mic,
                      color: clCleanWhite,
                      size: 24,
                    ),
                  ),
                ),

                // Hang up
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    onPressed: _hangUp,
                    icon: Icon(
                      Icons.call_end,
                      color: clCleanWhite,
                      size: 30,
                    ),
                  ),
                ),

                // Switch camera
                CircleAvatar(
                  radius: 30,
                  backgroundColor: clLightSkyGray.withOpacity(0.7),
                  child: IconButton(
                    onPressed: _switchCamera,
                    icon: Icon(
                      Icons.switch_camera,
                      color: clCleanWhite,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: accentColor),
            SizedBox(height: 20),
            Text(
              'Initializing call...',
              style: TextStyle(
                color: clCleanWhite,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}