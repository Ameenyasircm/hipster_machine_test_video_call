import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/user_view_alert.dart';
import '../../widgets/logout_alert.dart';
import '../providers/users_list_provider.dart';

// Assuming clDeepBlue and clCleanWhite are defined in your colors.dart
// Example definitions (if not provided):
/*
const Color clDeepBlue = Color(0xFF0A1828); // Deep, dark background
const Color clCleanWhite = Color(0xFFF5F5F5); // Nearly white
const Color clLightSkyGray = Color(0xFFA0B3C9); // Light gray for subtle text
*/

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserListProvider>(context);

    // Define the vibrant color for accents (Butterfly theme gradient start)
    const Color accentColor = Color(0xFF00C6FF); // Bright Cyan/Blue
    // Define the secondary color for gradient/contrast
    const Color secondaryAccent = Color(0xFF8A2BE2); // Blue-Violet

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
            color: clLightSkyGray, // Subtler color for non-primary action
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
                      // TODO: Implement navigation to a UserDetailsScreen
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

// SignalingService? _signalingService;
// callNext(
// UserCallScreen(
// loginUserId: "12345", // required user ID
// autoAccept: true, // bool, not string
// callId: "abc123", // optional, can also be null
// signalingService: _signalingService, // pass your SignalingService instance
// ),
// context,
// );
// // TODO: Implement navigation to the video call screen
// ScaffoldMessenger.of(context).showSnackBar(
// SnackBar(content: Text('Starting call with ${user.name}')),
// );