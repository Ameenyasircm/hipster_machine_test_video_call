import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../core/utils/signaling_service.dart';
import '../../data/models/user_model.dart';

class UserCallScreen extends StatefulWidget {
  final String loginUserId;
  final AppUser? targetUser; // target user to call
  final bool autoAccept;
  final SignalingService? signalingService;

  const UserCallScreen({
    Key? key,
    required this.loginUserId,
    this.targetUser,
    this.autoAccept = false,
    this.signalingService,
  }) : super(key: key);

  @override
  _UserCallScreenState createState() => _UserCallScreenState();
}

class _UserCallScreenState extends State<UserCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  late SignalingService _signaling;

  bool _inCall = false;
  bool _incomingCall = false;
  bool _showLocalVideo = false;
  String _callStatus = 'waiting';
  String? _callId;
  String? _callerName = 'MP';

  @override
  void initState() {
    print('FROFMRJIMRFR ');
    super.initState();
    _callId = widget.targetUser?.id;
    _initRenderers();
    _initSignaling();

    // Auto-accept call
    if (widget.autoAccept && widget.targetUser?.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _acceptCall();
      });
    }
  }

  void _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _initSignaling() {
    _signaling = widget.signalingService ??
        SignalingService(
          onRemoteStream: (stream) {
            print('Remote stream received with ${stream.getTracks().length} tracks');
            if (mounted) {
              setState(() {
                _remoteRenderer.srcObject = stream;
                _callStatus = 'active';
                _inCall = true;
              });
            }
          },
          onCallEnded: () {
            print('Call ended');
            _resetCall();
          },
          onCallStatusChanged: (status) {
            print('Call status changed: $status');
            if (mounted) {
              setState(() => _callStatus = status);
              if (status == 'ended' || status == 'rejected') _resetCall();
            }
          },
          onIncomingCall: (callId) {
            print('Incoming call: $callId');
            if (mounted) {
              setState(() {
                _incomingCall = true;
                _callStatus = 'incoming';
                _callId = callId;
              });
              _showIncomingCallDialog();
            }
          },
        );

    _signaling.listenForIncomingCalls(widget.loginUserId);

    if (widget.targetUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startOutgoingCall(widget.targetUser!);
      });
    }
  }

  void _startOutgoingCall(AppUser target) async {
    print('Starting outgoing call to ${target.name}');
    setState(() {
      _showLocalVideo = true;
      _callStatus = 'connecting';
    });

    // Ensure local media is ready
    await _signaling.initializeMedia();

    if (_signaling.localStream != null) {
      setState(() {
        _localRenderer.srcObject = _signaling.localStream;
      });
    }

    // Start the call
    await _signaling.createCall(target.id);
  }

  void _acceptCall() async {
    print('Accepting call...');
    setState(() {
      _incomingCall = false;
      _showLocalVideo = true;
      _callStatus = 'connecting';
    });

    // Initialize local media stream
    await _signaling.initializeMedia();

    if (_signaling.localStream != null) {
      setState(() => _localRenderer.srcObject = _signaling.localStream);
    }

    // Accept the call
    await _signaling.acceptCall();
  }

  void _rejectCall() {
    _signaling.rejectCall();
    _resetCall();
    Navigator.of(context).pop();
  }

  void _endCall() {
    _signaling.endCall();
    _resetCall();
    Navigator.of(context).pop();
  }

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

  void _showIncomingCallDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text('Incoming Video Call', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$_callerName is calling you', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: _rejectCall,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.call_end, color: Colors.white),
                    heroTag: "reject",
                  ),
                  FloatingActionButton(
                    onPressed: _acceptCall,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.videocam, color: Colors.white),
                    heroTag: "accept",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (_callStatus) {
      case 'waiting': return 'Waiting for calls...';
      case 'incoming': return 'Incoming call from $_callerName';
      case 'connecting': return 'Connecting...';
      case 'active': return 'In call with $_callerName';
      case 'ended': return 'Call ended';
      case 'rejected': return 'Call rejected';
      default: return 'Ready';
    }
  }

  Color _getStatusColor() {
    switch (_callStatus) {
      case 'waiting': return Colors.blue;
      case 'incoming': return Colors.orange;
      case 'connecting': return Colors.orange;
      case 'active': return Colors.green;
      case 'ended':
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
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
                SizedBox(height: 8),
                Text(_getStatusText(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getStatusColor())),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              child: _inCall
                  ? Stack(
                children: [
                  if (_callStatus == 'active')
                    Positioned.fill(
                      child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                    ),
                  if (_showLocalVideo)
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
                          child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                        ),
                      ),
                    ),
                  if (_callStatus == 'connecting')
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              SizedBox(height: 20),
                              Text('Connecting to call...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
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
                    Icon(Icons.phone_disabled, size: 80, color: Colors.grey[400]),
                    SizedBox(height: 20),
                    Text('No active calls', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
          if (_inCall)
            Container(
              padding: EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: _endCall,
                icon: Icon(Icons.call_end, color: Colors.white),
                label: Text('End Call', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    if (!widget.autoAccept) _signaling.dispose();
    super.dispose();
  }
}
