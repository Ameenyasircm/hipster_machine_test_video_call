// lib/features/video_call/screens/user_call_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../core/utils/call_service.dart';
// Note: Ensure you have 'flutter_webrtc' in your pubspec.yaml


class UserCallScreen extends StatefulWidget {
  final String? callId;
  final String loginUserId;
  final bool autoAccept;
  final SignalingService signalingService; // <-- remove "?"

  const UserCallScreen({
    Key? key,
    this.callId,
    this.autoAccept = false,
    required this.signalingService, // <-- mark required
    required this.loginUserId,
  }) : super(key: key);


  @override
  _UserCallScreenState createState() => _UserCallScreenState();
}

class _UserCallScreenState extends State<UserCallScreen> {
  // Renderers for displaying local and remote video streams
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  late SignalingService _signaling;

  bool _inCall = false;
  bool _incomingCall = false;
  bool _showLocalVideo = false;
  String _callStatus = 'waiting';
  String? _callId;
  String? _callerName = 'MP'; // Placeholder for caller's name

  @override
  void initState() {
    super.initState();
    _callId = widget.callId;
    _initRenderers();
    _initSignaling();

    // If auto-accept is true (i.e., this screen was navigated to for an incoming call),
    // accept the call immediately after the build cycle completes.
    if (widget.autoAccept && widget.callId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _acceptCall();
      });
    }
  }

  // Initialize the WebRTC video renderers
  void _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _initSignaling() {
    print("SignalingService provided: ${widget.signalingService != null}");

    // Check if a SignalingService instance was passed (e.g., from the caller screen)
    if (widget.signalingService != null) {
      _signaling = widget.signalingService!;
      // Update callbacks so the new stream data is piped to *this* screen's renderers
      _updateSignalingCallbacks();

      // Set initial stream states if the service already has them
      if (_signaling.localStream != null) {
        setState(() {
          _localRenderer.srcObject = _signaling.localStream;
          _showLocalVideo = true;
          _inCall = true; // Assume in call if local stream is ready
        });
      }
    } else {
      // If no service was passed (e.g., if this screen is the main entry point
      // for receiving calls in the background), create a new one.
      _signaling = SignalingService(
        onRemoteStream: (MediaStream stream) {
          setState(() {
            _remoteRenderer.srcObject = stream;
          });
          print('Remote stream received in new signaling instance');
        },
        onCallEnded: () {
          _resetCall();
          // Navigator.of(context).pop(); // Pop if call ends when not in call screen
        },
        onIncomingCall: (callId) {
          setState(() {
            _incomingCall = true;
            _callStatus = 'incoming';
            _callId = callId;
          });
          print('Incoming call received: $callId');
          _showIncomingCallDialog();
        },
        onCallStatusChanged: (String status) {
          setState(() {
            _callStatus = status;
          });
          print('Call status changed to: $status');

          if (status == 'ended' || status == 'rejected') {
            _resetCall();
          }
        },
      );
      // Start listening for incoming calls
      _signaling.listenForIncomingCalls(widget.loginUserId);
    }
  }

  // Update the service callbacks to use this screen's state management
  void _updateSignalingCallbacks() {
    _signaling.onRemoteStream = (MediaStream stream) {
      if (mounted) {
        setState(() {
          _remoteRenderer.srcObject = stream;
          _callStatus = 'active';
          _inCall = true; // Set in call when remote stream arrives
        });
        print('Remote stream received in user call screen');
      }
    };

    _signaling.onCallEnded = () {
      if (mounted) {
        _resetCall();
        // Automatically close the screen if the call ends
        Navigator.of(context).pop();
      }
    };

    _signaling.onCallStatusChanged = (String status) {
      if (mounted) {
        setState(() {
          _callStatus = status;
        });
        print('Call status changed to: $status');

        if (status == 'ended' || status == 'rejected') {
          // Automatically close the screen if the call is rejected or ended externally
          if (_inCall) Navigator.of(context).pop();
          _resetCall();
        }
      }
    };
  }

  // Dialog for handling incoming calls
  void _showIncomingCallDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent dismissing with back button
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Incoming Video Call',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_callerName is calling you',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Reject Button
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _rejectCall();
                      },
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.call_end, color: Colors.white),
                      heroTag: "reject",
                    ),
                    // Accept Button
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _acceptCall();
                      },
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.videocam, color: Colors.white),
                      heroTag: "accept",
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Logic to accept the call
  void _acceptCall() async {
    try {
      setState(() {
        _incomingCall = false;
        _inCall = true;
        _showLocalVideo = true;
        _callStatus = 'connecting';
      });

      await _signaling.acceptCall();

      if (_signaling.localStream != null) {
        setState(() {
          _localRenderer.srcObject = _signaling.localStream;
        });
      }
      print('Call accepted');
    } catch (e) {
      print('Error accepting call: $e');
      _showErrorDialog('Failed to accept call: $e');
    }
  }

  // Logic to reject the call
  void _rejectCall() {
    _signaling.rejectCall();
    _resetCall();
    // Pop the call screen after rejecting
    Navigator.of(context).pop();
  }

  // Logic to end the call (triggered by user button)
  void _endCall() {
    _signaling.endCall();
    // Pop the call screen after ending
    Navigator.of(context).pop();
  }

  // Reset state variables and renderers
  void _resetCall() {
    setState(() {
      _inCall = false;
      _incomingCall = false;
      _showLocalVideo = false;
      _callStatus = 'waiting';
      _callId = null;
    });
    _remoteRenderer.srcObject = null;
    _localRenderer.srcObject = null;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetCall();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (_callStatus) {
      case 'waiting':
        return 'Waiting for calls...';
      case 'calling':
        return 'Calling $_callerName...';
      case 'incoming':
        return 'Incoming call from $_callerName';
      case 'connecting':
        return 'Connecting...';
      case 'active':
        return 'In call with $_callerName';
      case 'ended':
        return 'Call ended';
      case 'rejected':
        return 'Call rejected';
      default:
        return 'Ready';
    }
  }

  Color _getStatusColor() {
    switch (_callStatus) {
      case 'waiting':
        return Colors.blue;
      case 'incoming':
        return Colors.orange;
      case 'connecting':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'ended':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_inCall, // Prevent back navigation if actively in a call
      child: Scaffold(
        body: Column(
          children: [
            // Status indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 40, bottom: 16, left: 16, right: 16),
              color: _getStatusColor().withOpacity(0.1),
              child: Column(
                children: [
                  Icon(
                    _callStatus == 'active'
                        ? Icons.videocam
                        : _callStatus == 'incoming'
                        ? Icons.phone_in_talk
                        : Icons.phone_disabled,
                    color: _getStatusColor(),
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                ],
              ),
            ),

            // Video display area
            Expanded(
              child: Container(
                color: Colors.black,
                child: _inCall
                    ? Stack(
                  children: [
                    // Remote video (full screen)
                    if (_callStatus == 'active')
                      Positioned.fill(
                        child: RTCVideoView(
                          _remoteRenderer,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),

                    // Local video (small overlay)
                    if (_showLocalVideo && _localRenderer.srcObject != null)
                      Positioned(
                        top: 20,
                        right: 20,
                        width: 120,
                        height: 160,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: RTCVideoView(
                              _localRenderer,
                              mirror: true,
                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            ),
                          ),
                        ),
                      ),

                    // Connecting overlay
                    if (_callStatus == 'connecting' || _callStatus == 'calling')
                      Positioned.fill(
                        child: Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Connecting...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                )
                    : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_disabled,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No active calls',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Control buttons (only show end call when in call)
            if (_inCall)
              Container(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: _endCall,
                  icon: const Icon(Icons.call_end, color: Colors.white),
                  label: const Text('End Call', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    // Only dispose signaling if it's not the global one (i.e., if it was created here)
    if (widget.signalingService == null) {
      _signaling.dispose();
    }
    super.dispose();
  }
}