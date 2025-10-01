import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../pages/video_call_screen.dart';

class CallProvider with ChangeNotifier {
  bool _isDialogShowing = false;
  String? _activeCallId;
  StreamSubscription? _callSubscription;

  bool get isDialogShowing => _isDialogShowing;
  String? get activeCallId => _activeCallId;

  // Call this when user logs in or app starts
  void listenForIncomingCalls(BuildContext context, String loggedInUserId) {
    // Cancel any existing subscription first
    _callSubscription?.cancel();

    _callSubscription = FirebaseFirestore.instance
        .collection('calls')
        .where('receiverId', isEqualTo: loggedInUserId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        // Only process newly added calls
        if (change.type == DocumentChangeType.added) {
          final callDoc = change.doc;
          final callData = callDoc.data();

          if (callData == null) continue;

          final channelName = callData['channelName'];
          final callerId = callData['callerId'];
          final status = callData['status'];

          // Prevent duplicate dialogs
          if (_isDialogShowing ||
              _activeCallId == channelName ||
              status != 'ringing') {
            continue;
          }

          // Fetch caller's name from users collection
          _fetchCallerNameAndShowDialog(
              context,
              callerId,
              channelName,
              loggedInUserId
          );
        }
      }
    });
  }

  Future<void> _fetchCallerNameAndShowDialog(
      BuildContext context,
      String callerId,
      String channelName,
      String loggedInUserId,
      ) async {
    String callerName = 'Unknown User';

    try {
      // Fetch caller's name from Firestore (adjust collection name if needed)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(callerId)
          .get();

      if (userDoc.exists) {
        callerName = userDoc.data()?['name'] ?? 'Unknown User';
      }
    } catch (e) {
      print('Error fetching caller name: $e');
    }

    // Check if context is still valid and widget is mounted
    if (!context.mounted) return;

    _isDialogShowing = true;
    _activeCallId = channelName;
    notifyListeners();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(Icons.phone_in_talk, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text("Incoming Call"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              callerName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'is calling you...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          // Decline button
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              _isDialogShowing = false;
              _activeCallId = null;
              notifyListeners();

              // Update call status to ended
              try {
                await FirebaseFirestore.instance
                    .collection('calls')
                    .doc(channelName)
                    .update({'status': 'ended'});
              } catch (e) {
                print('Error declining call: $e');
              }
            },
            icon: Icon(Icons.call_end, color: Colors.red),
            label: Text(
              "Decline",
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),

          // Accept button
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              _isDialogShowing = false;
              _activeCallId = null;
              notifyListeners();

              // Navigate to video call screen as RECEIVER
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoCallingScreen(
                      loginUserId: loggedInUserId,
                      channelName: channelName,
                      targetUserName: callerName,
                      isCaller: false, // IMPORTANT: This is the receiver
                    ),
                  ),
                );
              }
            },
            icon: Icon(Icons.videocam, color: Colors.white),
            label: Text(
              "Accept",
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      // Reset dialog state when dismissed
      _isDialogShowing = false;
      _activeCallId = null;
      notifyListeners();
    });
  }

  // Call this when user logs out or disposes
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  // Stop listening (useful when navigating away)
  void stopListening() {
    _callSubscription?.cancel();
    _isDialogShowing = false;
    _activeCallId = null;
    notifyListeners();
  }
}