// The helper widget DetailRow remains the same and is necessary for this code to run.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../features/auth/data/models/user_model.dart';

void showUserDetailsDialog(BuildContext context, UserModel user) {
  // Define the vibrant colors (should match the screen's accents)
  const Color accentColor = Color(0xFF00C6FF); // Bright Cyan/Blue
  const Color clDeepBlue = Color(0xFF0A1828); // Deep, dark background
  const Color clCleanWhite = Color(0xFFF5F5F5); // Nearly white
  const Color clLightSkyGray = Color(0xFFA0B3C9); // Light gray for subtle text

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        // Dark background for the dialog
        backgroundColor: clDeepBlue.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          // Subtle gradient border for the dialog edge
          side: BorderSide(color: accentColor.withOpacity(0.4), width: 1.5),
        ),

        contentPadding: const EdgeInsets.all(24),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 1. User Avatar with Accent Ring
            // (Avatar logic is unchanged)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accentColor, Color(0xFF8A2BE2)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: clDeepBlue,
                child: Text(
                  user.name.isNotEmpty ? user.name[0] : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: clCleanWhite,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. User Name (Title)
            Text(
              user.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: clCleanWhite,
              ),
            ),

            const SizedBox(height: 12),

            // 3. User Details Rows

            // Username
            DetailRow(
              icon: Icons.person_outline, // New icon for username
              label: 'Username:',
              value: user.username,
              accentColor: accentColor,
              clLightSkyGray: clLightSkyGray,
            ),

            // Email
            DetailRow(
              icon: Icons.alternate_email,
              label: 'Email:',
              value: user.email,
              accentColor: accentColor,
              clLightSkyGray: clLightSkyGray,
            ),

            // Phone (Now works because UserModel has phone property)
            if (user.phone != null && user.phone!.isNotEmpty)
              DetailRow(
                icon: Icons.phone_android,
                label: 'Phone:',
                value: user.phone!, // Use the non-null assertion since we checked
                accentColor: accentColor,
                clLightSkyGray: clLightSkyGray,
              ),

            // Website (Now works because UserModel has website property)
            if (user.website != null && user.website!.isNotEmpty)
              DetailRow(
                icon: Icons.language,
                label: 'Website:',
                value: user.website!, // Use the non-null assertion since we checked
                accentColor: accentColor,
                clLightSkyGray: clLightSkyGray,
              ),
          ],
        ),

        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text(
              'CLOSE',
              style: TextStyle(
                color: accentColor, // Vibrant button text
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}


// Small helper widget for consistent detail row layout
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Color clLightSkyGray;

  // Assuming clCleanWhite is also defined in your constants
  static const Color clCleanWhite = Color(0xFFF5F5F5);

  const DetailRow({
    super.key, // Added key for best practice
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.clLightSkyGray,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Icon (Vibrant Color)
          Icon(icon, color: accentColor.withOpacity(0.8), size: 20),
          const SizedBox(width: 8),

          // 2. Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label (e.g., "Email:", "Phone:")
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: clLightSkyGray, // Subtle, light gray color
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Value (The actual user data)
                Text(
                  value,
                  // Use SoftWrap to ensure long text wraps gracefully
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 15,
                    color: clCleanWhite, // High-contrast white color
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}