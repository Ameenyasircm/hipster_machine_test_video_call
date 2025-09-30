// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'CallService.dart';
//
// class UserScreen extends StatefulWidget {
//   final String loginUserId;
//   const UserScreen({super.key, required this.loginUserId});
//   @override
//   _UserScreenState createState() => _UserScreenState();
// }
//
// class _UserScreenState extends State<UserScreen> {
//   final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
//   final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
//   late SignalingService _signaling;
//
//   bool _inCall = false;
//   bool _incomingCall = false;
//   bool _showLocalVideo = false;
//   String _callStatus = 'waiting'; // waiting, incoming, active, ended
//   String? _callId;
//   String? _callerName = 'Admin';
//
//   @override
//   void initState() {
//     super.initState();
//     _initRenderers();
//     _initSignaling();
//   }
//
//   void _initRenderers() async {
//     await _localRenderer.initialize();
//     await _remoteRenderer.initialize();
//   }
//
//   void _initSignaling() {
//     _signaling = SignalingService(
//       onRemoteStream: (MediaStream stream) {
//         setState(() {
//           _remoteRenderer.srcObject = stream;
//         });
//         print('Remote stream received in user screen');
//       },
//       onCallEnded: () {
//         _resetCall();
//       },
//       onIncomingCall: (callId) {
//         setState(() {
//           _incomingCall = true;
//           _callStatus = 'incoming';
//           _callId = callId;
//         });
//         print('Incoming call received: $callId');
//         _showIncomingCallDialog();
//       },
//       onCallStatusChanged: (String status) {
//         setState(() {
//           _callStatus = status;
//         });
//         print('Call status changed to: $status');
//
//         if (status == 'ended' || status == 'rejected') {
//           _resetCall();
//         }
//       },
//     );
//
//     // Start listening for incoming calls
//     _signaling.listenForIncomingCalls(widget.loginUserId); // Replace with actual user ID
//   }
//
//   void _showIncomingCallDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return WillPopScope(
//           onWillPop: () async => false, // Prevent dismissing with back button
//           child: AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             title: Column(
//               children: [
//                 CircleAvatar(
//                   radius: 40,
//                   backgroundColor: Colors.blue,
//                   child: Icon(
//                     Icons.person,
//                     size: 40,
//                     color: Colors.white,
//                   ),
//                 ),
//                 SizedBox(height: 16),
//                 Text(
//                   'Incoming Video Call',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   '$_callerName is calling you',
//                   style: TextStyle(fontSize: 16),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: 20),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     // Reject button
//                     FloatingActionButton(
//                       onPressed: () {
//                         Navigator.of(context).pop();
//                         _rejectCall();
//                       },
//                       backgroundColor: Colors.red,
//                       child: Icon(Icons.call_end, color: Colors.white),
//                       heroTag: "reject",
//                     ),
//                     // Accept button
//                     FloatingActionButton(
//                       onPressed: () {
//                         Navigator.of(context).pop();
//                         _acceptCall();
//                       },
//                       backgroundColor: Colors.green,
//                       child: Icon(Icons.videocam, color: Colors.white),
//                       heroTag: "accept",
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   void _acceptCall() async {
//     try {
//       setState(() {
//         _incomingCall = false;
//         _inCall = true;
//         _showLocalVideo = true;
//         _callStatus = 'connecting';
//       });
//
//       await _signaling.acceptCall();
//
//       // Set local video immediately after accepting
//       if (_signaling.localStream != null) {
//         setState(() {
//           _localRenderer.srcObject = _signaling.localStream;
//         });
//       }
//
//       print('Call accepted');
//     } catch (e) {
//       print('Error accepting call: $e');
//       _showErrorDialog('Failed to accept call: $e');
//     }
//   }
//
//   void _rejectCall() {
//     _signaling.rejectCall();
//     _resetCall();
//   }
//
//   void _endCall() {
//     _signaling.endCall();
//   }
//
//   void _resetCall() {
//     setState(() {
//       _inCall = false;
//       _incomingCall = false;
//       _showLocalVideo = false;
//       _callStatus = 'waiting';
//       _callId = null;
//     });
//     _remoteRenderer.srcObject = null;
//     _localRenderer.srcObject = null;
//   }
//
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) =>
//           AlertDialog(
//             title: Text('Error'),
//             content: Text(message),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   _resetCall();
//                 },
//                 child: Text('OK'),
//               ),
//             ],
//           ),
//     );
//   }
//
//   String _getStatusText() {
//     switch (_callStatus) {
//       case 'waiting':
//         return 'Waiting for calls...';
//       case 'incoming':
//         return 'Incoming call from $_callerName';
//       case 'connecting':
//         return 'Connecting...';
//       case 'active':
//         return 'In call with $_callerName';
//       case 'ended':
//         return 'Call ended';
//       case 'rejected':
//         return 'Call rejected';
//       default:
//         return 'Ready';
//     }
//   }
//
//   Color _getStatusColor() {
//     switch (_callStatus) {
//       case 'waiting':
//         return Colors.blue;
//       case 'incoming':
//         return Colors.orange;
//       case 'connecting':
//         return Colors.orange;
//       case 'active':
//         return Colors.green;
//       case 'ended':
//       case 'rejected':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title: Text('User - Video Call'),
//           backgroundColor: Colors.green,
//           foregroundColor: Colors.white,
//         ),
//         body: Column(
//             children: [
//               // Status indicator
//               Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.all(16),
//                 color: _getStatusColor().withOpacity(0.1),
//                 child: Column(
//                   children: [
//                     Icon(
//                       _callStatus == 'active'
//                           ? Icons.videocam
//                           : _callStatus == 'incoming'
//                           ? Icons.phone_in_talk
//                           : Icons.phone_disabled,
//                       color: _getStatusColor(),
//                       size: 24,
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       _getStatusText(),
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: _getStatusColor(),
//                       ),
//                     ),
//                     if (_callId != null) ...[
//                       SizedBox(height: 4),
//                       Text(
//                         'Call ID: $_callId',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//
//               // Video display area
//               Expanded(
//                   child: Container(
//                       color: Colors.black,
//                       child: _inCall ? Stack(
//                         children: [
//                           // Remote video (full screen)
//                           if (_callStatus == 'active')
//                             Positioned.fill(
//                               child: RTCVideoView(
//                                 _remoteRenderer,
//                                 objectFit: RTCVideoViewObjectFit
//                                     .RTCVideoViewObjectFitCover,
//                               ),
//                             ),
//
//                           // Local video (small overlay)
//                           if (_showLocalVideo)
//                             Positioned(
//                               top: 20,
//                               right: 20,
//                               width: 120,
//                               height: 160,
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(color: Colors.white,
//                                       width: 2),
//                                 ),
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(10),
//                                   child: RTCVideoView(
//                                     _localRenderer,
//                                     mirror: true,
//                                     objectFit: RTCVideoViewObjectFit
//                                         .RTCVideoViewObjectFitCover,
//                                   ),
//                                 ),
//                               ),
//                             ),
//
//                           // Connecting overlay
//                           if (_callStatus == 'connecting')
//                             Positioned.fill(
//                               child: Container(
//                                 color: Colors.black54,
//                                 child: Center(
//                                   child: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       CircularProgressIndicator(
//                                         valueColor: AlwaysStoppedAnimation<
//                                             Color>(Colors.white),
//                                       ),
//                                       SizedBox(height: 20),
//                                       Text(
//                                         'Connecting to call...',
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ) : Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.phone_disabled,
//                                 size: 80,
//                                 color: Colors.grey[400],
//                               ),
//                               SizedBox(height: 20),
//                               Text(
//                                 'No active calls',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                             ],
//                           )
//                       )
//                   )
//               )
//             ])
//     );
//   }
// }

///
///
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../core/utils/call_service.dart';

class UserCallScreen extends StatefulWidget {
  final String? callId;
  final String loginUserId;

  final bool autoAccept;
  final SignalingService? signalingService;

  const UserCallScreen({
    Key? key,
    this.callId,
    this.autoAccept = false,
    this.signalingService,
    required this.loginUserId
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
    super.initState();
    _callId = widget.callId;
    // _signaling = widget.signalingService!;
    _initRenderers();
    _initSignaling();

    // If auto-accept is true, accept the call immediately
    if (widget.autoAccept && widget.callId != null) {
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
    print("gggggggggggggggggg _initSignaling  ${widget.signalingService}");
    // Use existing signaling service if provided, otherwise create new one
    if (widget.signalingService != null) {
      _signaling = widget.signalingService!;
      // Update callbacks for this screen
      _updateSignalingCallbacks();

      // If there's already a local stream, set it immediately
      if (_signaling.localStream != null) {
        setState(() {
          _localRenderer.srcObject = _signaling.localStream;
          _showLocalVideo = true;
        });
      }

      // If there's already a remote stream, set it immediately
      // if (_signaling.remoteStream != null) {
      //   setState(() {
      //     _remoteRenderer.srcObject = _signaling.remoteStream;
      //   });
      // }
    } else {
      _signaling = SignalingService(
        onRemoteStream: (MediaStream stream) {
          setState(() {
            _remoteRenderer.srcObject = stream;
          });
          print('Remote stream received in user screen');
        },
        onCallEnded: () {
          _resetCall();
          // Navigator.of(context).pop();
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

      // Start listening for incoming calls only if not using global service
      _signaling.listenForIncomingCalls(widget.loginUserId);
    }
  }

  void _updateSignalingCallbacks() {
    // Create new callbacks that work with this screen's renderers
    _signaling.onRemoteStream = (MediaStream stream) {
      if (mounted) {
        setState(() {
          _remoteRenderer.srcObject = stream;
          _callStatus = 'active';
        });
        print('Remote stream received in user call screen');
      }
    };

    _signaling.onCallEnded = () {
      if (mounted) {
        _resetCall();
        // Navigator.of(context).pop();
      }
    };

    _signaling.onCallStatusChanged = (String status) {
      if (mounted) {
        setState(() {
          _callStatus = status;
        });
        print('Call status changed to: $status');

        if (status == 'ended' || status == 'rejected') {
          _resetCall();
        }
      }
    };

    // Don't override onIncomingCall if using global service
    // as it should be handled by GlobalCallManager
  }

  void _showIncomingCallDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Incoming Video Call',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text( 'MP is calling youff',
                  // '$_callerName is calling you',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _rejectCall();
                      },
                      backgroundColor: Colors.red,
                      child: Icon(Icons.call_end, color: Colors.white),
                      heroTag: "reject",
                    ),
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _acceptCall();
                      },
                      backgroundColor: Colors.green,
                      child: Icon(Icons.videocam, color: Colors.white),
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

  void _rejectCall() {
    _signaling.rejectCall();
    _resetCall();
    Navigator.of(context).pop();
    // Navigate back if this screen was opened for the call
    // if (widget.autoAccept) {
    //   Navigator.of(context).pop();
    // }
  }

  void _endCall() {
    _signaling.endCall();
    // Navigate back if this screen was opened for the call
    Navigator.of(context).pop();
    // if (widget.autoAccept) {
    //   Navigator.of(context).pop();
    // }
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetCall();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (_callStatus) {
      case 'waiting':
        return 'Waiting for calls...';
      case 'incoming':
        return 'Incoming call from MP'; //$_callerName';
      case 'connecting':
        return 'Connecting...';
      case 'active':
        return 'In call with MP'; // $_callerName';
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
      canPop: !_inCall, // Prevent back if in call
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Dispose logic runs automatically if `canPop` is true
          // No need to manually handle anything unless you want extra cleanup
        }
      },
      child: Scaffold(
        // appBar: AppBar(
        //   title: Text('User - Video Call'),
        //   backgroundColor: Colors.green,
        //   foregroundColor: Colors.white,
        // ),
        body: Column(
          children: [
            // Status indicator
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
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                  // if (_callId != null) ...[
                  //   SizedBox(height: 4),
                  //   Text(
                  //     'Call ID: $_callId',
                  //     style: TextStyle(
                  //       fontSize: 12,
                  //       color: Colors.grey[600],
                  //     ),
                  //   ),
                  // ],
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
                            child: RTCVideoView(
                              _localRenderer,
                              mirror: true,
                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            ),
                          ),
                        ),
                      ),

                    // Connecting overlay
                    if (_callStatus == 'connecting')
                      Positioned.fill(
                        child: Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Connecting to call...',
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
                      SizedBox(height: 20),
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
                padding: EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: _endCall,
                  icon: Icon(Icons.call_end, color: Colors.white),
                  label: Text('End Call', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    // Only dispose signaling if it's not the global one
    if (!widget.autoAccept) {
      _signaling.dispose();
    }
    super.dispose();
  }
}