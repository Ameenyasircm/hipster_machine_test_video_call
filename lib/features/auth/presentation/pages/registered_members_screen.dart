// lib/features/users/screens/users_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/signaling_service.dart'; // Assuming this is needed elsewhere
import '../providers/users_list_provider.dart'; // Import the new provider

// Mock Colors (Ensure these are defined in your colors.dart)
const Color clDeepBlue = Color(0xFF0F1828);
const Color clCleanWhite = Color(0xFFF5F5F5);
const Color clLightSkyGray = Color(0xFFA0B3C9);
const Color accentColor = Color(0xFF00C6FF);
const Color secondaryAccent = Color(0xFF8A2BE2);


class RegisteredUsersScreen extends StatelessWidget {
  const RegisteredUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserListProvider>(context);

    return Scaffold(
      backgroundColor: clDeepBlue,
      appBar: AppBar(
        title: const Text('Registered Users', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: clDeepBlue,
        foregroundColor: clCleanWhite,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: accentColor,
            // 1. UPDATED FUNCTION NAME
            onPressed: () => provider.fetchRegisteredUsers(),
          ),
        ],
      ),
      body: FutureBuilder(
        // 2. UPDATED LIST NAME AND FUNCTION NAME
        future: provider.registeredUsers.isEmpty ? provider.fetchRegisteredUsers() : null,
        builder: (context, snapshot) {

          // 3. UPDATED LIST NAME
          if (provider.isLoading && provider.registeredUsers.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Text(
                'Error: ${provider.errorMessage}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          // 4. UPDATED LIST NAME
          if (provider.registeredUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_alt_outlined, size: 60, color: clLightSkyGray.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  const Text(
                    "No users found. Try registering a new user.",
                    style: TextStyle(color: clLightSkyGray, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            // 5. UPDATED LIST NAME FOR ITEM COUNT (Crucial for preventing RangeError)
            itemCount: provider.registeredUsers.length,
            itemBuilder: (context, index) {
              // 6. CORRECTLY ACCESSING THE REGISTERED USERS LIST
              final AppUser user = provider.registeredUsers[index];
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
          borderRadius: BorderRadius.circular(12),
          // Subtle dark gradient background
          gradient: LinearGradient(
            colors: [
              secondaryAccent.withOpacity(0.1),
              accentColor.withOpacity(0.1),
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

          // Avatar with gradient border
          leading: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accentColor, secondaryAccent],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: clDeepBlue.withOpacity(0.9),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: clCleanWhite,
                ),
              ),
            ),
          ),

          // User Name
          title: Text(
            user.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: clCleanWhite,
            ),
          ),

          // User Phone Number and Email
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone: ${user.phoneNumber}',
                style: TextStyle(
                  fontSize: 13,
                  color: clLightSkyGray.withOpacity(0.7),
                ),
              ),
              Text(
                'Email: ${user.email}',
                style: TextStyle(
                  fontSize: 13,
                  color: clLightSkyGray.withOpacity(0.7),
                ),
              ),
            ],
          ),

          // Action: Example video call button
          trailing: IconButton(
            icon: const Icon(Icons.videocam),
            color: accentColor,
            onPressed: () {
              // TODO: Implement call initiation here, similar to previous discussion
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Call button tapped for ${user.name}')),
              );
            },
          ),
          onTap: () {
            // Optional: Navigate to user details screen
          },
        ),
      ),
    );
  }
}