import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
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

    // ✅ Remove native splash after a tiny delay to show Flutter splash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Remove native splash immediately when Flutter UI is ready
      FlutterNativeSplash.remove();
    });

    // Start navigation timer
    Timer(const Duration(seconds: 3), () {
      checkLoginStatus();
    });
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userID = prefs.getString('userId').toString();
    final userName   = prefs.getString('name').toString();

    if (isLoggedIn) {
      callNextReplacement( UsersListScreen(userName:userID ,userID: userName,), context);
    } else {
      callNextReplacement(const LoginScreen(), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: clDeepBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/AppLogoPng.png'),
            const SizedBox(height: 24),
            Text(
              'Hipster Machine Test',
              style: TextStyle(
                color: clCleanWhite,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}