// lib/features/users/screens/users_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hipster_machine_test/features/auth/presentation/pages/video_call_screen.dart';
import 'package:provider/provider.dart';

// Import the new VideoCallingScreen
import '../../../../core/constants/colors.dart'; // Assume this path is correct
import '../../data/models/registered_members_model.dart';
import '../../data/models/user_model.dart';
import '../providers/users_list_provider.dart';



// Assuming clDeepBlue, accentColor, clLightSkyGray are defined in colors.dart

class RegisteredUsersScreen extends StatelessWidget {
  final String currentLoginUserId;

  RegisteredUsersScreen({Key? key, required this.currentLoginUserId}) : super(key: key);

  void _initiateCall(BuildContext context, AppUser targetUser) async {
    // 1. Create a unique channel name per call
    String channelName = "${currentLoginUserId}_${targetUser.id}_${DateTime.now().millisecondsSinceEpoch}";

    // 2. Save call info in Firestore (initial setup)
    final callDoc = FirebaseFirestore.instance.collection('calls').doc(channelName);
    await callDoc.set({
      'callerId': currentLoginUserId,
      'receiverId': targetUser.id,
      'channelName': channelName,
      'status': 'ringing', // ringing, accepted, ended
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Navigate to VideoCallingScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallingScreen(
          loginUserId: currentLoginUserId,
          channelName: channelName,
          targetUserName: targetUser.name,
          isCaller: true, // This user is initiating the call
        ),
      ),
    );

    // Optional: show connecting snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${targetUser.name}...')),
    );
  }

  // Listener to handle incoming calls (outside the main build)
  void _listenForIncomingCalls(BuildContext context) {
    FirebaseFirestore.instance
        .collection('calls')
        .where('receiverId', isEqualTo: currentLoginUserId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        // Handle only the most recent call
        final callData = snapshot.docs.first.data();
        final channelName = callData['channelName'];
        final callerId = callData['callerId'];

        // Prevent showing dialog multiple times
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          _showIncomingCallDialog(context, channelName, callerId);
        }
      }
    });
  }

  void _showIncomingCallDialog(BuildContext context, String channelName, String callerId) {
    // Look up caller's name (requires another db fetch or a local cache)
    // For simplicity, we'll use a placeholder or another fetch.
    String callerName = "Another User"; // Replace with actual name fetch if needed

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Incoming Call from $callerName"),
          content: const Text("Do you want to accept the video call?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Decline", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Update call status to 'ended'
                FirebaseFirestore.instance.collection('calls').doc(channelName).update({'status': 'ended'});
              },
            ),
            TextButton(
              child: const Text("Accept", style: TextStyle(color: accentColor)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Navigate to VideoCallingScreen as receiver
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoCallingScreen(
                      loginUserId: currentLoginUserId,
                      channelName: channelName,
                      targetUserName: callerName, // Placeholder
                      isCaller: false, // This user is the receiver
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Start listening for incoming calls as soon as the screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForIncomingCalls(context);
    });

    final provider = Provider.of<UserListProvider>(context);

    return Scaffold(
      backgroundColor: clDeepBlue,
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white)),
        title: const Text('Registered Users', style: TextStyle(color: Colors.white)),
        backgroundColor: clDeepBlue,
      ),
      body: FutureBuilder(
        future: provider.registeredUsers.isEmpty && !provider.isLoading
            ? provider.fetchRegisteredUsers()
            : null,
        builder: (context, snapshot) {
          if (provider.isLoading && provider.registeredUsers.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }
          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error loading users: ${provider.errorMessage}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: clLightSkyGray, fontSize: 16),
                ),
              ),
            );
          }
          if (provider.registeredUsers.isEmpty) {
            return const Center(
              child: Text(
                'No registered users found.',
                style: TextStyle(color: clLightSkyGray, fontSize: 16),
              ),
            );
          }

          // Filter out the current logged-in user from the list
          final displayUsers = provider.registeredUsers.where((user) => user.id != currentLoginUserId).toList();

          if (displayUsers.isEmpty) {
            return const Center(
              child: Text(
                'No other users found.',
                style: TextStyle(color: clLightSkyGray, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: displayUsers.length,
            itemBuilder: (context, index) {
              final AppUser user = displayUsers[index];
              return _buildUserListItem(context, user);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserListItem(BuildContext context, AppUser user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: clDeepBlue.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor.withOpacity(0.5)),
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(user.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          title: Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phone: ${user.phoneNumber}', style: TextStyle(color: clLightSkyGray.withOpacity(0.7))),
              Text('Email: ${user.email}', style: TextStyle(color: clLightSkyGray.withOpacity(0.7))),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.videocam),
            color: accentColor,
            onPressed: () => _initiateCall(context, user),
          ),
          onTap: () {
            // Optional: Navigate to user details screen
          },
        ),
      ),
    );
  }
}