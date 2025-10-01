// lib/features/users/screens/users_list_screen.dart

import 'package:flutter/material.dart';
import 'package:hipster_machine_test/features/auth/presentation/pages/video_call_screen.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
// ✅ FIXED: Use the same import as user_call_screen.dart
import '../../../../core/utils/call_service.dart';
import '../../../../core/utils/functions.dart';
import '../../../../core/utils/signaling_service.dart' hide SignalingService;
import '../../data/models/user_model.dart';
import '../providers/users_list_provider.dart';

class RegisteredUsersScreen extends StatelessWidget {
  final String currentLoginUserId = "1759252605383";

  const RegisteredUsersScreen({Key? key}) : super(key: key);

// ... inside RegisteredUsersScreen ...

  void _initiateCall(BuildContext context, AppUser targetUser) async {
    const String currentLoginUserId = "1759253582218";

    // 1. DO NOT create SignalingService here.
    // 2. DO NOT start the call here.

    // Navigate to call screen, passing the necessary data for it to start the call.
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => UserCallScreen(
    //       loginUserId: currentLoginUserId,
    //       targetUser: null,        // no target for incoming
    //       signalingService: null,  // let the screen handle service
    //       autoAccept: true,        // automatically accept the incoming call
    //     ),
    //   ),
    // );

    callNextReplacement(UserCallScreen(
      // callId: callId,
      // autoAccept: true,
      // signalingService: _signalingService,
      loginUserId: currentLoginUserId,
    ), context);
    // Optional: Show a brief "Connecting..." snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connecting to ${targetUser.name}...')),
    );
  }

// ... rest of RegisteredUsersScreen remains the same ...
  @override
  Widget build(BuildContext context) {
    // Listen to the provider for state changes
    final provider = Provider.of<UserListProvider>(context);

    return Scaffold(
      backgroundColor: clDeepBlue,
      appBar: AppBar(
        title: const Text('Registered Users', style: TextStyle(color: Colors.white)),
        backgroundColor: clDeepBlue,
      ),
      body: FutureBuilder(
        // Fetch users only if the list is empty AND we're not already loading.
        // This logic ensures 'fetchRegisteredUsers' is called once on initial load.
        future: provider.registeredUsers.isEmpty && !provider.isLoading
            ? provider.fetchRegisteredUsers()
            : null,
        builder: (context, snapshot) {

          // --- FIX: The guaranteed return of a sized widget in all states ---

          // 1. Loading State
          if (provider.isLoading && provider.registeredUsers.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }

          // 2. Error State
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

          // 3. Empty State (after loading or if data is truly empty)
          if (provider.registeredUsers.isEmpty) {
            return const Center(
              child: Text(
                'No registered users found.',
                style: TextStyle(color: clLightSkyGray, fontSize: 16),
              ),
            );
          }

          // 4. Data Available State
          // This ListView.builder will be properly sized by the Scaffold's body.
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: provider.registeredUsers.length,
            itemBuilder: (context, index) {
              final AppUser user = provider.registeredUsers[index];
              return _buildUserListItem(context, user);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserListItem(BuildContext context, AppUser user) {
    // This Padding widget is the one referred to in the error.
    // Since its parent is the ListView.builder, which provides unbounded height
    // constraints (but manages the scrolling and viewport), this widget itself
    // will now be laid out correctly as a child of the list.
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
            decoration: BoxDecoration(
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

