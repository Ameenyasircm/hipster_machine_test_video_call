// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
// import 'package:provider/provider.dart';
//
// import '../../notification/notification_view_model.dart';
// import '../models/booking_model.dart';
//
// class SignalingService {
//   final Function(MediaStream) onRemoteStream;
//   final Function() onCallEnded;
//   final Function(String) onIncomingCall;
//   final Function(String) onCallStatusChanged;
//
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   RTCPeerConnection? _peerConnection;
//   MediaStream? _localStream;
//   String? _callId;
//   String? _targetUserId;
//   String? _currentUserId;
//   StreamSubscription<DocumentSnapshot>? _callStatusSubscription;
//   StreamSubscription<QuerySnapshot>? _candidatesSubscription;
//   StreamSubscription<QuerySnapshot>? _incomingCallsSubscription;
//
//   List<Booking> _bookedUserIds = [];
//   int _currentUserIndex = 0;
//
//   String? get callId => _callId;
//   MediaStream? get localStream => _localStream;
//
//   SignalingService({
//     required this.onRemoteStream,
//     required this.onCallEnded,
//     required this.onIncomingCall,
//     required this.onCallStatusChanged,
//   });
//
//   Future<void> _setupPeerConnection() async {
//     final configuration = <String, dynamic>{
//       'iceServers': [
//         {'urls': 'stun:stun.l.google.com:19302'},
//         {'urls': 'stun:stun1.l.google.com:19302'},
//       ],
//       'sdpSemantics': 'unified-plan',
//     };
//
//     _peerConnection = await createPeerConnection(configuration);
//
//     _peerConnection!.onTrack = (RTCTrackEvent event) {
//       if (event.streams.isNotEmpty) {
//         print('Received remote stream');
//         onRemoteStream(event.streams[0]);
//       }
//     };
//
//     _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
//       if (candidate.candidate != null && _callId != null) {
//         _addIceCandidate(candidate);
//       }
//     };
//
//     _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
//       print('Connection state: $state');
//     };
//
//     _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
//       print('Ice connection state: $state');
//     };
//   }
//
//   Future<void> _addIceCandidate(RTCIceCandidate candidate) async {
//     try {
//       final collection = _currentUserId == 'admin' ? 'offerCandidates' : 'answerCandidates';
//       await _firestore
//           .collection('calls')
//           .doc(_callId)
//           .collection(collection)
//           .add(candidate.toMap());
//     } catch (e) {
//       print('Error adding ICE candidate: $e');
//     }
//   }
//
//   Future<void> startCall(String targetUserId, String currentUserId, BuildContext context,List<Booking> bookedUsers) async {
//     print("entered start call function $_currentUserIndex");
//     try {
//       _targetUserId = targetUserId;
//       _currentUserId = currentUserId;
//       _callId = DateTime.now().millisecondsSinceEpoch.toString();
//
//       Booking receiverId = bookedUsers[_currentUserIndex];
//
//       print("_targetUserId = $targetUserId; _currentUserId = $currentUserId;  _callId = $_callId  receiverId = $receiverId");
//
//       await _setupPeerConnection();
//       await _getUserMedia();
//
//       // Create and set local description
//       final offer = await _peerConnection!.createOffer();
//       await _peerConnection!.setLocalDescription(offer);
//
//       print("qqqqqqqqqqqqqqqqqqqqqqqqq");
//
//       // Save call to Firestore
//       await _firestore.collection('calls').doc(_callId).set({
//         'callerId': _currentUserId,
//         'targetUserId': _targetUserId,
//         'offer': offer.toMap(),
//         'status': 'ringing',
//         'createdAt': FieldValue.serverTimestamp(),
//       });
//
//       print('Call initiated with ID: $_callId');
//       onCallStatusChanged('ringing');
//
//       NotificationProvider provider = Provider.of<NotificationProvider>(context,listen: false);
//       provider.sendPushNotification(
//         "You Have A Call",
//         "Would you Like To Join?",
//         context, receiverId.bookedUserFCM,
//       );
//
//       // Listen for call status changes
//       _listenForCallStatusChanges();
//
//       // Listen for answer
//       _listenForAnswer();
//
//       // Listen for remote ICE candidates
//       _listenForRemoteCandidates('answerCandidates');
//
//     } catch (e) {
//       print('Error starting call: $e');
//       onCallStatusChanged('error');
//     }
//   }
//
//   Future<void> _getUserMedia() async {
//     try {
//       _localStream = await navigator.mediaDevices.getUserMedia({
//         'audio': true,
//         'video': {
//           'facingMode': 'user',
//           'width': {'ideal': 640},
//           'height': {'ideal': 480},
//         }
//       });
//
//       // Add tracks to peer connection
//       _localStream!.getTracks().forEach((track) {
//         _peerConnection!.addTrack(track, _localStream!);
//       });
//     } catch (e) {
//       print('Error getting user media: $e');
//       throw e;
//     }
//   }
//
//   void _listenForCallStatusChanges() {
//     _callStatusSubscription = _firestore
//         .collection('calls')
//         .doc(_callId)
//         .snapshots()
//         .listen((snapshot) {
//       if (snapshot.exists) {
//         final status = snapshot.data()?['status'];
//         if (status != null) {
//           onCallStatusChanged(status);
//           if (status == 'ended' || status == 'rejected') {
//             _cleanup();
//           }
//         }
//       }
//     });
//   }
//
//   void _listenForAnswer() {
//     _firestore
//         .collection('calls')
//         .doc(_callId)
//         .snapshots()
//         .listen((snapshot) async {
//       if (snapshot.exists) {
//         final data = snapshot.data();
//         if (data?['answer'] != null && _peerConnection != null) {
//           try {
//             final answer = RTCSessionDescription(
//               data!['answer']['sdp'],
//               data['answer']['type'],
//             );
//             await _peerConnection!.setRemoteDescription(answer);
//             print('Remote description set successfully');
//           } catch (e) {
//             print('Error setting remote description: $e');
//           }
//         }
//       }
//     });
//   }
//
//   void _listenForRemoteCandidates(String collection) {
//     _candidatesSubscription = _firestore
//         .collection('calls')
//         .doc(_callId)
//         .collection(collection)
//         .snapshots()
//         .listen((snapshot) {
//       for (var change in snapshot.docChanges) {
//         if (change.type == DocumentChangeType.added) {
//           final data = change.doc.data() as Map<String, dynamic>;
//           try {
//             _peerConnection!.addCandidate(RTCIceCandidate(
//               data['candidate'],
//               data['sdpMid'],
//               data['sdpMLineIndex'],
//             ));
//           } catch (e) {
//             print('Error adding remote candidate: $e');
//           }
//         }
//       }
//     });
//   }
//
//   void listenForIncomingCalls(String userId) {
//     _currentUserId = userId;
//     _incomingCallsSubscription = _firestore
//         .collection('calls')
//         .where('targetUserId', isEqualTo: userId)
//         .where('status', isEqualTo: 'ringing')
//         .snapshots()
//         .listen((snapshot) {
//       for (var change in snapshot.docChanges) {
//         if (change.type == DocumentChangeType.added) {
//           final callData = change.doc.data() as Map<String, dynamic>;
//           _callId = change.doc.id;
//           _targetUserId = callData['callerId'];
//           print('Incoming call from: $_targetUserId');
//           onIncomingCall(_callId!);
//         }
//       }
//     });
//   }
//
//   Future<void> acceptCall() async {
//     try {
//       if (_callId == null) return;
//
//       await _setupPeerConnection();
//       await _getUserMedia();
//
//       // Get the offer from Firestore
//       final callDoc = await _firestore.collection('calls').doc(_callId).get();
//       if (!callDoc.exists) return;
//
//       final callData = callDoc.data()!;
//       final offer = RTCSessionDescription(
//         callData['offer']['sdp'],
//         callData['offer']['type'],
//       );
//
//       await _peerConnection!.setRemoteDescription(offer);
//
//       // Create answer
//       final answer = await _peerConnection!.createAnswer();
//       await _peerConnection!.setLocalDescription(answer);
//
//       // Update call status and add answer
//       await _firestore.collection('calls').doc(_callId).update({
//         'answer': answer.toMap(),
//         'status': 'active',
//       });
//
//       print('Call accepted');
//       onCallStatusChanged('active');
//
//       // Listen for remote ICE candidates
//       _listenForRemoteCandidates('offerCandidates');
//
//       // Listen for call status changes
//       _listenForCallStatusChanges();
//
//     } catch (e) {
//       print('Error accepting call: $e');
//       onCallStatusChanged('error');
//     }
//   }
//
//   Future<void> rejectCall() async {
//     if (_callId != null) {
//       await _firestore.collection('calls').doc(_callId).update({
//         'status': 'rejected',
//       });
//     }
//     _cleanup();
//   }
//
//   Future<void> endCall() async {
//     print("zdfsdfsdf $_callId");
//     if (_callId != null) {
//       await _firestore.collection('calls').doc(_callId).update({
//         'status': 'ended',
//       });
//     }
//     _cleanup();
//   }
//
//   void _cleanup() {
//     _callStatusSubscription?.cancel();
//     _candidatesSubscription?.cancel();
//     _incomingCallsSubscription?.cancel();
//
//     _peerConnection?.close();
//     _peerConnection = null;
//
//     _localStream?.dispose();
//     _localStream = null;
//
//     _callId = null;
//     _targetUserId = null;
//
//     onCallEnded();
//   }
//
//   void dispose() {
//     _cleanup();
//   }
// }

///
///
///
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/presentation/providers/notification_provider.dart';

typedef OnRemoteStream = void Function(MediaStream stream);
typedef OnCallEnded = void Function();
typedef OnIncomingCall = void Function(String callId);
typedef OnCallStatusChanged = void Function(String status);

class SignalingService {
  //  late final Function(MediaStream) onRemoteStream;
  // late final Function() onCallEnded;
  // late final Function(String) onIncomingCall;
  // late final Function(String) onCallStatusChanged;
  late  Function(MediaStream) onRemoteStream;
  late  Function() onCallEnded;
  late  Function(String) onIncomingCall;
  late  Function(String) onCallStatusChanged;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  String? _callId;
  String? _targetUserId;
  String? _currentUserId;
  StreamSubscription<DocumentSnapshot>? _callStatusSubscription;
  StreamSubscription<QuerySnapshot>? _candidatesSubscription;
  StreamSubscription<QuerySnapshot>? _incomingCallsSubscription;

  List<Booking> _bookedUserIds = [];
  int _currentUserIndex = 0;
  Timer? _noAnswerTimer;
  bool _isGlobalService = false;
  bool _isInitialized = false;

  String? get callId => _callId;
  MediaStream? get localStream => _localStream;
  bool get isInCall => _callId != null && _peerConnection != null;
  String? get currentUserId => _currentUserId;

  SignalingService({
    required this.onRemoteStream,
    required this.onCallEnded,
    required this.onIncomingCall,
    required this.onCallStatusChanged,
    bool isGlobal = false,
  }) : _isGlobalService = isGlobal;

  // Initialize the service for global use
  Future<void> initializeGlobal(String userId) async {
    if (_isInitialized) return;

    _currentUserId = userId;
    _isGlobalService = true;
    _isInitialized = true;

    // Start listening for incoming calls immediately
    listenForIncomingCalls(userId);
    print('Global SignalingService initialized for user: $userId');
  }

  // Update callbacks for different screens
  void updateCallbacks({
    Function(MediaStream)? onRemoteStream,
    Function()? onCallEnded,
    Function(String)? onIncomingCall,
    Function(String)? onCallStatusChanged,
  }) {
    if (onRemoteStream != null) this.onRemoteStream = onRemoteStream;
    if (onCallEnded != null) this.onCallEnded = onCallEnded;
    if (onIncomingCall != null) this.onIncomingCall = onIncomingCall;
    if (onCallStatusChanged != null) this.onCallStatusChanged = onCallStatusChanged;
  }

  Future<void> _setupPeerConnection() async {
    if (_peerConnection != null) {
      await _peerConnection!.close();
    }

    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
      ],
      'iceCandidatePoolSize': 10,
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        print('Received remote stream');
        onRemoteStream(event.streams[0]);
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null && _callId != null) {
        _addIceCandidate(candidate);
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        onCallStatusChanged('active');
        _cancelNoAnswerTimer();
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        if (_callId != null) {
          _handleCallFailure();
        }
      }
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      print('Ice connection state: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        onCallStatusChanged('active');
        _cancelNoAnswerTimer();
      }
    };
  }

  Future<void> _addIceCandidate(RTCIceCandidate candidate) async {
    try {
      final collection = _currentUserId == 'admin' ||
          (_currentUserId?.contains('admin') ?? false) ?
      'offerCandidates' : 'answerCandidates';

      await _firestore
          .collection('calls')
          .doc(_callId)
          .collection(collection)
          .add(candidate.toMap());
    } catch (e) {
      print('Error adding ICE candidate: $e');
    }
  }

  Future<void> startCall(String targetUserId, String currentUserId, BuildContext context, List<Booking> bookedUsers) async {
    print("Entered start call function. Current user index: $_currentUserIndex");

    try {
      _bookedUserIds = bookedUsers;
      _targetUserId = targetUserId;
      _currentUserId = currentUserId;
      _callId = '${DateTime.now().millisecondsSinceEpoch}_${currentUserId}_to_$targetUserId';

      if (_currentUserIndex >= bookedUsers.length) {
        print('No more users to call');
        onCallStatusChanged('ended');
        return;
      }

      Booking receiverId = bookedUsers[_currentUserIndex];
      print("Calling user: ${receiverId.userId} (${receiverId.name})");

      await _setupPeerConnection();
      await _getUserMedia();

      // Create and set local description
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // // Create offer
      // RTCSessionDescription offer = await _peerConnection!.createOffer({});
      // String sdpOffer = _setBandwidthAndCodec(offer.sdp!);
      // await _peerConnection!.setLocalDescription(
      //   RTCSessionDescription(sdpOffer, offer.type),
      // );

      // Save call to Firestore
      await _firestore.collection('calls').doc(_callId).set({
        'callerId': _currentUserId,
        'targetUserId': receiverId.userId,
        'targetUserName': receiverId.name,
        'offer': offer.toMap(),
        'status': 'ringing',
        'createdAt': FieldValue.serverTimestamp(),
        'callType': 'video',
      });

      await _firestore.collection('BOOKINGS').doc(receiverId.id).set({'isCalled':true}, SetOptions(merge: true));

      print('Call initiated with ID: $_callId to user: ${receiverId.userId}');
      onCallStatusChanged('ringing');

      // Send push notification
      if (context.mounted) {
        NotificationProvider provider = Provider.of<NotificationProvider>(context, listen: false);
        await provider.sendPushNotification(
          "You Have A Video Call",
          "MP is calling you. Tap to answer.",
          context,
          receiverId.bookedUserFCM,
        );
      }

      // Set up no-answer timer (30 seconds)
      _startNoAnswerTimer();

      // Listen for call status changes
      _listenForCallStatusChanges();

      // Listen for answer
      _listenForAnswer();

      // Listen for remote ICE candidates
      _listenForRemoteCandidates('answerCandidates');

    } catch (e) {
      print('Error starting call: $e');
      onCallStatusChanged('error');
      _cleanup();
    }
  }

  /// Set bandwidth and prefer VP8 codec in SDP
  String _setBandwidthAndCodec(String sdp) {
    // Limit video bandwidth to 1Mbps and prefer VP8
    sdp = sdp.replaceAllMapped(
      RegExp(r'm=video \d+ [\w/]+'),
          (match) => '${match.group(0)}\r\nb=AS:1000\r\nb=TIAS:1000000',
    );
    // Optionally, implement codec prioritization here
    return sdp;
  }

  void _startNoAnswerTimer() {
    _cancelNoAnswerTimer();
    _noAnswerTimer = Timer(Duration(seconds: 30), () {
      print('No answer timeout - trying next user');
      _handleNoAnswer();
    });
  }

  void _cancelNoAnswerTimer() {
    _noAnswerTimer?.cancel();
    _noAnswerTimer = null;
  }

  Future<void> _handleNoAnswer() async {
    print('Handling no answer scenario');

    // Mark current call as no answer
    if (_callId != null) {
      try {
        await _firestore.collection('calls').doc(_callId).update({
          'status': 'no_answer',
          'endedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating call status: $e');
      }
    }

    // Try next user
    _currentUserIndex++;

    if (_currentUserIndex < _bookedUserIds.length) {
      print('Trying next user: ${_currentUserIndex + 1}/${_bookedUserIds.length}');
      _cleanup(shouldNotifyEnd: false);

      // Small delay before trying next user
      await Future.delayed(Duration(milliseconds: 500));

      // Try calling the next user
      if (_bookedUserIds.isNotEmpty) {
        String nextUserId = _bookedUserIds[_currentUserIndex].userId;
        // This would need to be called from the admin screen
        onCallStatusChanged('trying_next');
      }
    } else {
      print('All users tried, ending call sequence');
      onCallStatusChanged('all_users_tried');
      _cleanup();
    }
  }

  Future<void> _handleCallFailure() async {
    print('Handling call failure');
    _cancelNoAnswerTimer();

    if (_callId != null) {
      try {
        await _firestore.collection('calls').doc(_callId).update({
          'status': 'failed',
          'endedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating failed call: $e');
      }
    }

    onCallStatusChanged('failed');
    _cleanup();
  }

  Future<void> _getUserMedia() async {
    try {
      // Dispose existing stream if any
      if (_localStream != null) {
        _localStream!.dispose();
        _localStream = null;
      }

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640, 'max': 1280},
          'height': {'ideal': 480, 'max': 720},
          'frameRate': {'ideal': 15, 'max': 30},
        }
      });

      // Add tracks to peer connection
      if (_peerConnection != null) {
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
        });
      }
    } catch (e) {
      print('Error getting user media: $e');
      throw e;
    }
  }

  void _listenForCallStatusChanges() {
    _callStatusSubscription?.cancel();

    _callStatusSubscription = _firestore
        .collection('calls')
        .doc(_callId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final status = data['status'];

        if (status != null) {
          print('Call status changed to: $status');
          onCallStatusChanged(status);

          if (status == 'ended' || status == 'rejected' || status == 'failed') {
            _cancelNoAnswerTimer();
            _cleanup();
          } else if (status == 'active') {
            _cancelNoAnswerTimer();
          }
        }
      }
    }, onError: (error) {
      print('Error listening for call status changes: $error');
    });
  }

  void _listenForAnswer() {
    _firestore
        .collection('calls')
        .doc(_callId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data['answer'] != null && _peerConnection != null) {
          try {
            final answer = RTCSessionDescription(
              data['answer']['sdp'],
              data['answer']['type'],
            );
            await _peerConnection!.setRemoteDescription(answer);
            print('Remote description set successfully');
            _cancelNoAnswerTimer();
          } catch (e) {
            print('Error setting remote description: $e');
          }
        }
      }
    }, onError: (error) {
      print('Error listening for answer: $error');
    });
  }

  void _listenForRemoteCandidates(String collection) {
    _candidatesSubscription?.cancel();

    _candidatesSubscription = _firestore
        .collection('calls')
        .doc(_callId)
        .collection(collection)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          try {
            if (_peerConnection != null) {
              _peerConnection!.addCandidate(RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              ));
            }
          } catch (e) {
            print('Error adding remote candidate: $e');
          }
        }
      }
    }, onError: (error) {
      print('Error listening for remote candidates: $error');
    });
  }

  void listenForIncomingCalls(String userId) {
    if (_incomingCallsSubscription != null) {
      _incomingCallsSubscription!.cancel();
    }

    _currentUserId = userId;
    print('Starting to listen for incoming calls for user: $userId');

    _incomingCallsSubscription = _firestore
        .collection('calls')
        .where('targetUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final callData = change.doc.data() as Map<String, dynamic>;
          final incomingCallId = change.doc.id;
          final callerId = callData['callerId'];

          print('Incoming call detected: $incomingCallId from $callerId');

          // Set current call details
          _callId = incomingCallId;
          _targetUserId = callerId;

          onIncomingCall(incomingCallId);
        }
      }
    }, onError: (error) {
      print('Error listening for incoming calls: $error');
    });
  }

  Future<void> acceptCall() async {
    try {
      if (_callId == null) {
        print('No call ID available for accepting');
        return;
      }

      print('Accepting call: $_callId');

      await _setupPeerConnection();
      await _getUserMedia();

      // Get the offer from Firestore
      final callDoc = await _firestore.collection('calls').doc(_callId).get();
      if (!callDoc.exists) {
        print('Call document not found');
        return;
      }

      final callData = callDoc.data()!;
      final offerData = callData['offer'];

      if (offerData == null) {
        print('No offer found in call document');
        return;
      }

      final offer = RTCSessionDescription(
        offerData['sdp'],
        offerData['type'],
      );

      await _peerConnection!.setRemoteDescription(offer);

      // Create answer
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Update call status and add answer
      await _firestore.collection('calls').doc(_callId).update({
        'answer': answer.toMap(),
        'status': 'active',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      print('Call accepted successfully');
      onCallStatusChanged('active');

      // Listen for remote ICE candidates
      _listenForRemoteCandidates('offerCandidates');

      // Listen for call status changes
      _listenForCallStatusChanges();

    } catch (e) {
      print('Error accepting call: $e');
      onCallStatusChanged('error');
      _cleanup();
    }
  }

  Future<void> rejectCall() async {
    print('Rejecting call: $_callId');

    if (_callId != null) {
      try {
        await _firestore.collection('calls').doc(_callId).update({
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
        });
        print('Call rejected successfully');
      } catch (e) {
        print('Error rejecting call: $e');
      }
    }

    _cleanup();
  }

  Future<void> endCall() async {
    print('Ending call: $_callId');

    _cancelNoAnswerTimer();

    if (_callId != null) {
      try {
        await _firestore.collection('calls').doc(_callId).update({
          'status': 'ended',
          'endedAt': FieldValue.serverTimestamp(),
        });
        print('Call ended successfully');
      } catch (e) {
        print('Error ending call: $e');
      }
    }

    _cleanup();
  }

  // Reset to call next user in the list (for admin)
  Future<void> callNextUser(BuildContext context) async {
    if (_bookedUserIds.isEmpty || _currentUserIndex >= _bookedUserIds.length - 1) {
      print('No more users to call');
      onCallStatusChanged('all_users_tried');
      return;
    }

    _currentUserIndex++;
    print('Moving to next user: ${_currentUserIndex + 1}/${_bookedUserIds.length}');

    // Clean up current call
    _cleanup(shouldNotifyEnd: false);

    // Start call with next user
    await Future.delayed(Duration(milliseconds: 500));
    String nextTargetUserId = _bookedUserIds[_currentUserIndex].userId;
    await startCall(nextTargetUserId, _currentUserId!, context, _bookedUserIds);
  }

  void _cleanup({bool shouldNotifyEnd = true}) {
    print('Cleaning up SignalingService');

    _cancelNoAnswerTimer();

    // Cancel subscriptions
    _callStatusSubscription?.cancel();
    _callStatusSubscription = null;

    _candidatesSubscription?.cancel();
    _candidatesSubscription = null;

    // Don't cancel incoming calls subscription for global service
    if (!_isGlobalService) {
      _incomingCallsSubscription?.cancel();
      _incomingCallsSubscription = null;
    }

    // Close peer connection
    _peerConnection?.close();
    _peerConnection = null;

    // Dispose local stream
    _localStream?.dispose();
    _localStream = null;

    // Reset call state
    _callId = null;
    _targetUserId = null;

    if (shouldNotifyEnd) {
      onCallEnded();
    }
  }

  void dispose() {
    print('Disposing SignalingService');
    _cleanup();

    // Cancel incoming calls subscription for global service
    if (_isGlobalService) {
      _incomingCallsSubscription?.cancel();
      _incomingCallsSubscription = null;
    }

    _isInitialized = false;
  }

  // Get call status
  Future<String?> getCallStatus(String callId) async {
    try {
      final doc = await _firestore.collection('calls').doc(callId).get();
      if (doc.exists) {
        return doc.data()?['status'];
      }
    } catch (e) {
      print('Error getting call status: $e');
    }
    return null;
  }

  // Check if user is available for calls
  Future<bool> isUserAvailable(String userId) async {
    try {
      final activeCallsQuery = await _firestore
          .collection('calls')
          .where('targetUserId', isEqualTo: userId)
          .where('status', whereIn: ['ringing', 'active'])
          .get();

      return activeCallsQuery.docs.isEmpty;
    } catch (e) {
      print('Error checking user availability: $e');
      return false;
    }
  }
}