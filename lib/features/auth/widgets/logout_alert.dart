import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/colors.dart';
import '../presentation/pages/login_screen.dart'; // Ensure this path is correct

// A common utility function to display the logout confirmation dialog
Future<void> showLogoutConfirmationDialog(BuildContext context) async {
  // Define the colors for the gradient for the 'Yes, Logout' button
  const Color gradientStart = Color(0xFF00C6FF);
  const Color gradientEnd = Color(0xFF8042F0);

  return showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap a button
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        // Use a dark background color for the AlertDialog to match the app theme
        backgroundColor: clDeepBlue.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          // Optional: Add a subtle border
          side: const BorderSide(color: gradientStart, width: 1.5),
        ),

        title: const Text(
          'Confirm Logout',
          style: TextStyle(
            color: clCleanWhite,
            fontWeight: FontWeight.bold,
          ),
        ),

        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                'Are you sure you want to log out from your account?',
                style: TextStyle(
                  color: clLightSkyGray, // Lighter text for content
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        actions: <Widget>[
          // 1. Cancel Button (Text Button - less emphasis)
          TextButton(
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: clLightSkyGray,
                fontSize: 16,
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Dismiss the dialog
            },
          ),

          // 2. Logout Button (The primary action - use the gradient style)
          GestureDetector(
            onTap: () async {
              // 1. Clear SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);

              // 2. Dismiss dialog first
              Navigator.of(dialogContext).pop();

              // 3. Navigate to the Login Screen and remove all previous routes
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [gradientStart, gradientEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: const Text(
                'Yes, Logout',
                style: TextStyle(
                  color: clCleanWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

// ==========================================================
// EXAMPLE USAGE:
// ==========================================================

/*
// In the build method of your main screen (e.g., UsersListScreen)

AppBar(
  title: const Text('User List'),
  backgroundColor: clDeepBlue,
  actions: [
    IconButton(
      icon: const Icon(Icons.logout, color: clCleanWhite),
      onPressed: () {
        // Call the function when the user taps the logout button
        showLogoutConfirmationDialog(context);
      },
    ),
  ],
),
*/