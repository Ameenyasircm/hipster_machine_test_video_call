import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hipster_machine_test/features/auth/presentation/pages/users_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../../../../core/constants/colors.dart';
import '../../../../core/utils/functions.dart';
import '../providers/login_provider.dart';
import 'login_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      checkLoginStatus();

    });
  }
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      print(isLoggedIn.toString()+' FRNRJKNRF ');
    // Wait for splash duration
    await Future.delayed(const Duration(seconds: 3));

    if (isLoggedIn) {
      // Navigate to main screen (UsersListScreen or VideoCallScreen)
      callNextReplacement(UsersListScreen(), context);
    } else {
      callNextReplacement(LoginScreen(), context);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the background color using the defined constant
      backgroundColor: clDeepBlue,
      body: Center(
        child: Column(
          // Center the content vertically
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. App Icon (Using the Flutter Dash icon as a high-contrast placeholder
            //    for the actual butterfly image asset)
            // If you have the image asset, use: Image.asset('assets/images/app_icon.png', height: 120)
            Image.asset('assets/AppLogoPng.png'),

            const SizedBox(height: 24), // Spacing between icon and text

            // 2. App Name Text "Machine Test"
            Text(
              'Hipster Machine Test',
              style: TextStyle(
                // Set text color using the defined constant
                color: clCleanWhite,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Ameen yasir',
              style: TextStyle(
                // Set text color using the defined constant
                color: clCleanWhite,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}