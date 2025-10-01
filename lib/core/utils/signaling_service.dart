// lib/core/utils/signaling_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final String currentUserId;
  final String channelName;
  final Function(MediaStream) onAddRemoteStream;
  final Function() onCallEnded;

  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _offerCreated = false;
  bool _answerCreated = false;
  StreamSubscription? _callSubscription;
  StreamSubscription? _candidateSubscription;
  List<RTCIceCandidate> _pendingCandidates = []; // Queue for pending candidates

  SignalingService({
    required this.currentUserId,
    required this.channelName,
    required this.onAddRemoteStream,
    required this.onCallEnded,
  });

  RTCPeerConnection? get peerConnection => _peerConnection;
  MediaStream? get localStream => _localStream;

  String get _callerId {
    final parts = channelName.split('_');
    return parts.isNotEmpty ? parts[0] : '';
  }

  String get _receiverId {
    final parts = channelName.split('_');
    return parts.length > 1 ? parts[1] : '';
  }

  bool get isCaller => currentUserId == _callerId;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _initializePeerConnection();
      await _getUserMedia();
      _setupPeerConnectionListeners();
      await _listenForRemoteSignaling();

      _isInitialized = true;
      print('SignalingService initialized successfully - isCaller: $isCaller');

      // Only create offer if we're the caller AND no offer exists yet
      if (isCaller) {
        _checkExistingCall();
      }
    } catch (e) {
      print('Error initializing signaling service: $e');
      rethrow;
    }
  }

  Future<void> _checkExistingCall() async {
    if (!isCaller) return; // 🚫 Receivers must never create offers

    try {
      final doc = await _firestore.collection('calls').doc(channelName).get();
      if (!doc.exists || !doc.data()!.containsKey('offer')) {
        await createOffer();
      } else {
        print('Existing call found, waiting for answer...');
      }
    } catch (e) {
      print('Error checking existing call: $e');
    }
  }

  Future<void> _initializePeerConnection() async {
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ]
    }, {
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ]
    });
    print('PeerConnection created');
  }

  Future<void> _getUserMedia() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'video': {
        'width': 640,
        'height': 480,
        'frameRate': 30,
      },
      'audio': true,
    });
    print('Local media stream obtained with ${_localStream!.getTracks().length} tracks');
  }

  void _setupPeerConnectionListeners() {
    // Add local tracks to peer connection
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
      print('Added local track: ${track.kind}');
    });

    // Handle incoming remote streams
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      print('=== REMOTE TRACK RECEIVED ===');
      print('Track kind: ${event.track?.kind}');
      print('Track id: ${event.track?.id}');
      print('Streams count: ${event.streams.length}');

      if (event.streams.isNotEmpty) {
        final remoteStream = event.streams[0];
        print('Remote stream received with ID: ${remoteStream.id}');

        // Notify UI about the remote stream
        onAddRemoteStream(remoteStream);
      }
    };

    // Handle ICE candidates
    _peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate == null) return;
      print('ICE candidate generated: ${candidate.candidate}');
      _sendIceCandidate(candidate);
    };

    // Handle connection state changes
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        print('=== PEER CONNECTION CONNECTED ===');
      }
    };

    _peerConnection!.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state: $state');
    };

    _peerConnection!.onSignalingState = (RTCSignalingState state) {
      print('Signaling state: $state');
    };
  }

  Future<void> _sendIceCandidate(RTCIceCandidate candidate) async {
    final collectionName = isCaller ? 'callerCandidates' : 'receiverCandidates';
    try {
      await _firestore
          .collection('calls')
          .doc(channelName)
          .collection(collectionName)
          .add(candidate.toMap());
      print('ICE candidate sent to $collectionName');
    } catch (e) {
      print('Error sending ICE candidate: $e');
    }
  }

  Future<void> _listenForRemoteSignaling() async {
    print('Listening for remote signaling...');

    // Listen for call document changes (SDP exchange)
    _callSubscription = _firestore
        .collection('calls')
        .doc(channelName)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists || _isDisposed) return;

      final data = snapshot.data()!;
      print('Call document updated: ${data.keys}');

      await _handleRemoteSdp(data);
      await _checkCallStatus(data);
    });

    // Listen for remote ICE candidates
    final remoteCandidateCollection = isCaller ? 'receiverCandidates' : 'callerCandidates';
    _candidateSubscription = _firestore
        .collection('calls')
        .doc(channelName)
        .collection(remoteCandidateCollection)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added && !_isDisposed) {
          print('Remote ICE candidate received');
          _handleRemoteIceCandidate(change.doc);
        }
      }
    });
  }

  Future<void> _handleRemoteSdp(Map<String, dynamic> data) async {
    try {
      // If we're the receiver and there's an offer AND we haven't created an answer yet
      if (!isCaller && data.containsKey('offer') && !_answerCreated) {
        print('Received offer as receiver - creating answer');
        final offer = RTCSessionDescription(data['offer']['sdp'], data['offer']['type']);

        // Set remote description first
        await _peerConnection!.setRemoteDescription(offer);
        print('Remote description set (offer)');

        // Process any pending ICE candidates
        await _processPendingCandidates();

        // Create answer
        _answerCreated = true;
        await createAnswer();
      }

      // If we're the caller and there's an answer
      if (isCaller && data.containsKey('answer') && _offerCreated) {
        print('Received answer as caller');
        final answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);

        await _peerConnection!.setRemoteDescription(answer);
        print('Remote description set (answer)');

        // Process any pending ICE candidates
        await _processPendingCandidates();
      }
    } catch (e) {
      print('Error handling remote SDP: $e');
    }
  }
  Future<void> _handleRemoteIceCandidate(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'] ?? '',
        data['sdpMLineIndex'] ?? 0,
      );

      // Try to add candidate immediately
      try {
        await _peerConnection!.addCandidate(candidate);
        print('Remote ICE candidate added to peer connection');
      } catch (e) {
        // If adding fails, queue the candidate for later
        print('Failed to add ICE candidate, queuing for later: $e');
        _pendingCandidates.add(candidate);
      }

      // Remove candidate from Firestore after processing
      await doc.reference.delete();
    } catch (e) {
      print('Error handling remote ICE candidate: $e');
      await doc.reference.delete();
    }
  }

  Future<void> _processPendingCandidates() async {
    if (_pendingCandidates.isEmpty) return;

    print('Processing ${_pendingCandidates.length} pending ICE candidates');
    for (final candidate in _pendingCandidates) {
      try {
        await _peerConnection!.addCandidate(candidate);
        print('Pending ICE candidate added to peer connection');
      } catch (e) {
        print('Failed to add pending ICE candidate: $e');
      }
    }
    _pendingCandidates.clear();
  }

  Future<void> _checkCallStatus(Map<String, dynamic> data) async {
    if (data['status'] == 'ended') {
      print('Call ended remotely');
      onCallEnded();
    }
  }

  Future<void> createOffer() async {
    if (_offerCreated) {
      print('Offer already created, skipping...');
      return;
    }

    try {
      print('Creating offer...');
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      print('Local description set (offer)');

      await _firestore.collection('calls').doc(channelName).set({
        'offer': offer.toMap(),
        'callerId': _callerId,
        'receiverId': _receiverId,
        'status': 'ringing',
        'channelName': channelName,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _offerCreated = true;
      print('Offer saved to Firestore');
    } catch (e) {
      print('Error creating offer: $e');
      rethrow;
    }
  }

  Future<void> createAnswer() async {
    if (_answerCreated) {
      print('Answer already created, skipping...');
      return;
    }

    try {
      print('Creating answer...');
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      print('Local description set (answer)');

      await _firestore.collection('calls').doc(channelName).update({
        'answer': answer.toMap(),
        'status': 'accepted',
        'answeredAt': FieldValue.serverTimestamp(),
      });

      _answerCreated = true;
      print('Answer saved to Firestore');
    } catch (e) {
      print('Error creating answer: $e');
      rethrow;
    }
  }
  Future<void> hangUp() async {
    _isDisposed = true;

    try {
      await _firestore.collection('calls').doc(channelName).update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      });
      print('Call ended in Firestore');
    } catch (e) {
      print('Error updating call status: $e');
    }

    await _cleanup();
  }

  Future<void> _cleanup() async {
    await _callSubscription?.cancel();
    await _candidateSubscription?.cancel();

    await _localStream?.dispose();
    _localStream = null;

    await _peerConnection?.close();
    _peerConnection = null;

    _isInitialized = false;
    _offerCreated = false;
    _answerCreated = false;
    _pendingCandidates.clear();
    print('SignalingService cleaned up');
  }

  void dispose() {
    _isDisposed = true;
    _cleanup();
  }
}