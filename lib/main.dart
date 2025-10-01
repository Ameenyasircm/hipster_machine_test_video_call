import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:hipster_machine_test/features/auth/presentation/pages/splash_screen.dart';
import 'package:hipster_machine_test/features/auth/presentation/providers/login_provider.dart';
import 'package:hipster_machine_test/features/auth/presentation/providers/users_list_provider.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/auth/presentation/pages/registration_screen.dart';
import 'features/auth/presentation/pages/users_list_screen.dart';
import 'features/auth/presentation/providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 1. Preserve native splash
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 2. Initialize Firebase
  await Firebase.initializeApp();

  // 3. Run app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ REMOVED: FlutterNativeSplash.remove() from here
    // It will be removed from SplashScreen instead

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LoginProvider()),
        ChangeNotifierProvider(create: (context) => UserListProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}