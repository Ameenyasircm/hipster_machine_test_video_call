import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hipster_machine_test/core/utils/functions.dart';
import 'package:hipster_machine_test/features/auth/presentation/pages/registered_members_screen.dart';
import 'package:hipster_machine_test/features/auth/presentation/pages/video_room_screen.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/user_view_alert.dart';
import '../../widgets/logout_alert.dart';
import '../providers/call_provider.dart';
import '../providers/users_list_provider.dart';


class UsersListScreen extends StatefulWidget {
  String userID, userName,from;
   UsersListScreen({Key? key,required this.userID, required this.userName, required this.from}) : super(key: key);

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  // Placeholder for your navigation function (replace with your actual implementation)
  void _navigateToVideoCallScreen(BuildContext context) {
    // This is where you would typically navigate to your video call initiation screen.
    // For demonstration, using a simple SnackBar and the commented-out logic.
    callNext(RegisteredUsersScreen(currentLoginUserId: widget.userID,), context);
  }

  bool _isDialogShowing = false;
  String? _activeCallId;

  @override
  void initState() {
    super.initState();
    // _listenForIncomingCalls();
    print(widget.userName+' RKJFRJK FR F');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CallProvider>(context, listen: false)
          .listenForIncomingCalls(context, widget.userName);
    });
  }

  void _listenForIncomingCalls() {
    final loggedInUserId = widget.userID;

    FirebaseFirestore.instance
        .collection('calls')
        .where('receiverId', isEqualTo: loggedInUserId)
        .where('status', isEqualTo: 'ringing')
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final callDoc = snapshot.docs.first;
        final callData = callDoc.data();
        final channelName = callData['channelName'];
        final callerId = callData['callerId'];

        // ✅ Prevent same dialog opening again
        if (_isDialogShowing && _activeCallId == channelName) return;

        _isDialogShowing = true;
        _activeCallId = channelName;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Incoming Call"),
            content: Text("User $callerId is calling you."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _isDialogShowing = false;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoCallingScreen(
                        loginUserId: loggedInUserId,
                        channelName: channelName,
                        targetUserName: callerId,
                      ),
                    ),
                  );

                  FirebaseFirestore.instance
                      .collection('calls')
                      .doc(channelName)
                      .update({'status': 'accepted'});
                },
                child: const Text("Accept"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _isDialogShowing = false;

                  FirebaseFirestore.instance
                      .collection('calls')
                      .doc(channelName)
                      .update({'status': 'ended'});
                },
                child: const Text("Decline"),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserListProvider>(context);
    print(widget.from+' FKJR JKF RF ');
    return Scaffold(
      // 1. Dark Background for the entire screen body
      backgroundColor: clDeepBlue,
      appBar: AppBar(
        title: const Text('Contacts', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: clDeepBlue,
        foregroundColor: clCleanWhite,
        elevation: 0, // Remove shadow for flat look
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: accentColor, // Use the primary accent color
            onPressed: () {
              provider.fetchUsers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.redAccent, // Use a standard color for danger action
            onPressed: () {
              // Assuming showLogoutConfirmationDialog is implemented elsewhere
              showLogoutConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: provider.fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              provider.usersList.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading users',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (provider.usersList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_alt_outlined, size: 60, color: clLightSkyGray.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  const Text(
                    "No contacts found",
                    style: TextStyle(color: clLightSkyGray, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: provider.usersList.length,
            itemBuilder: (context, index) {
              final user = provider.usersList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    // Use a subtle, dark gradient border for a modern look
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.1),
                        secondaryAccent.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    // 2. Avatar with Gradient Border and Initials
                    leading: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Use a subtle gradient ring around the avatar
                        gradient: LinearGradient(
                          colors: [accentColor, secondaryAccent],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: clDeepBlue.withOpacity(0.9), // Darker center
                        child: Text(
                          user.name.isNotEmpty ? user.name[0] : '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: clCleanWhite, // White text for maximum contrast
                          ),
                        ),
                      ),
                    ),

                    // 3. Title (User Name)
                    title: Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: clCleanWhite,
                      ),
                    ),

                    // 4. Subtitle (User Email/Status)
                    subtitle: Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: clLightSkyGray.withOpacity(0.7),
                      ),
                    ),

                    // 5. Trailing Icon (No video call, now a simple 'view' icon)
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded, // Standard list navigation indicator
                      size: 18,
                      color: clLightSkyGray.withOpacity(0.6),
                    ),

                    // 6. OnTap Action (Focus on navigation/profile view)
                    onTap: () {
                      // Navigate to User Profile/Details screen
                      showUserDetailsDialog(context,user);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),

      // --- FLOATING ACTION BUTTON ADDED HERE ---
      floatingActionButton: FloatingActionButton.extended(
        // Use a ShaderMask for the vibrant gradient effect on the background
        backgroundColor: Colors.transparent,
        onPressed: () => _navigateToVideoCallScreen(context),
        elevation: 8, // Add a slight lift
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),

        label: Ink(
          decoration: BoxDecoration(
            // Apply the gradient as a background to the FAB content area
            gradient: const LinearGradient(
              colors: [accentColor, secondaryAccent], // Blue to Purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 36.0, minWidth: 80.0),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam, color: clCleanWhite, size: 24),
                SizedBox(width: 8),
                Text(
                  'Video Call',
                  style: TextStyle(
                      color: clCleanWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // --- END FLOATING ACTION BUTTON ---

    );
  }
}