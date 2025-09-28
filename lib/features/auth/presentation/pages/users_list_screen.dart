import 'package:flutter/material.dart';
import 'package:hipster_machine_test/core/utils/functions.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../widgets/logout_alert.dart';
import '../providers/login_provider.dart';
import '../providers/users_list_provider.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserListProvider>(context);

    // Define the vibrant color for accents
    const Color accentColor = Color(0xFF00C6FF); // Bright gradient start color

    return Scaffold(
      // 1. Dark Background for the entire screen body
      backgroundColor: clDeepBlue,
      appBar: AppBar(
        title: const Text('Users List'),
        backgroundColor: clDeepBlue,
        foregroundColor: clCleanWhite,
        elevation: 0, // Remove shadow for flat look
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            // Use the accent color on the dark background
            color: accentColor,
            onPressed: () {
              provider.fetchUsers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            // Use the accent color on the dark background
            color: accentColor,
            onPressed: () {
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
              // Use a themed loading indicator
              child: CircularProgressIndicator(color: accentColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (provider.usersList.isEmpty) {
            return const Center(
              child: Text(
                "No users found",
                style: TextStyle(color: clLightSkyGray),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.usersList.length,
            itemBuilder: (context, index) {
              final user = provider.usersList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Card(
                  // 2. Card Design: Use a slightly lighter dark color for the card background
                  color: clDeepBlue.withOpacity(0.85),
                  elevation: 4, // Subtle elevation for floating effect
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    // Optional: Add a subtle border
                    side: BorderSide(color: accentColor.withOpacity(0.4), width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                    leading: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor, // Vibrant border for the avatar
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(user.avatar),
                        backgroundColor: clLightSkyGray, // Fallback background
                      ),
                    ),

                    title: Text(
                      user.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: clCleanWhite, // 3. White Text for Contrast
                      ),
                    ),

                    subtitle: Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: clLightSkyGray.withOpacity(0.8), // Lighter secondary text
                      ),
                    ),

                    trailing: const Icon(
                      Icons.videocam_outlined, // Changed to a video icon for context
                      size: 24,
                      color: accentColor, // Vibrant color for action icon
                    ),
                    onTap: () {
                      // TODO: Implement navigation to the video call screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Starting call with ${user.fullName}')),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}