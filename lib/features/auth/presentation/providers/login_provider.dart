  import 'dart:collection';
  import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hipster_machine_test/core/utils/functions.dart';
import 'package:hipster_machine_test/features/auth/presentation/pages/users_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
  import 'package:flutter/cupertino.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';

  class LoginProvider extends ChangeNotifier {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    bool _isLoading = false;
    bool get isLoading => _isLoading;

    String? _errorMessage;
    String? get errorMessage => _errorMessage;

    Map<String, dynamic>? _user;
    Map<String, dynamic>? get user => _user;

    Future<bool> login(String email, String password,BuildContext context) async {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      print(email+' FKRKF '+password);
      try {
        final querySnapshot = await db
            .collection('USERS')
            .where('email', isEqualTo: email.trim())
            .where('password', isEqualTo: password.trim())
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          print(' IRRJF ');
          final doc = querySnapshot.docs.first;
          _user = doc.data(); // ✅ this is Map<String, dynamic>

          // ✅ Safely extract values (null-aware)
          final String userId = _user?['id'] ?? '';
          final String userEmail = _user?['email'] ?? '';
          final String userName = _user?['name'] ?? '';
          final String userPhone = _user?['phoneNumber'] ?? '';
          final String fcmToken = _user?['fcmToken'] ?? '';

          // ✅ Save login state locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userId', userId);
          await prefs.setString('userEmail', userEmail);
          await prefs.setString('name', userName);
          await prefs.setString('phone', userPhone);
          await prefs.setString('fcmToken', fcmToken);

            // Navigate to User List Screen or Video Call Screen
            callNextReplacement(UsersListScreen(userID: userId,userName: userName,from: 'Login11',), context);

          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          print(' FIOR KFR ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage ?? 'Login failed')),
          );
          _errorMessage = "Invalid email or password";
        }
      } catch (e) {
        _errorMessage = "Login failed: $e";
        print("$e EJFMJRKF");
      }

      _isLoading = false;
      notifyListeners();
      return false;
    }

    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    // 💡 ADDED A DISPOSE METHOD
    void disposeControllers() {
      nameController.dispose();
      phoneController.dispose();
      emailController.dispose();
      passwordController.dispose();
    }

// In login_provider.dart:

// Assuming you have a way to access FirebaseFirestore.instance
// and have defined db, nameController, phoneController, etc.
// and the state management logic (_isLoading, _errorMessage, notifyListeners)
// and helper functions (getFcmToken, clearControllers, saveLoginState)

    Future<bool> register(BuildContext context) async {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // 💡 GET VALUES FROM CONTROLLERS
      final name = nameController.text.trim(); // Trim whitespace
      final phoneNumber = phoneController.text.trim(); // Trim whitespace
      final email = emailController.text.trim().toLowerCase(); // Trim and standardize email
      final password = passwordController.text;

      // You'll need to fetch the fcmToken, perhaps using a helper function
      // or a property in the provider itself.
      final fcmToken = await getFcmToken(); // 💡 ASSUMPTION: Replace with actual FCM logic

      try {
        // 1. Check if user with this EMAIL already exists
        var existingQuery = await db
            .collection('USERS')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (existingQuery.docs.isNotEmpty) {
          _errorMessage = "Email already registered.";
          _isLoading = false;
          notifyListeners();
          return false;
        }

        // 2. Check if user with this PHONE NUMBER already exists
        // This uses an OR-like query by checking separately since Firestore doesn't support
        // true logical OR for multiple `where` clauses on different fields unless using array-contains-any.
        existingQuery = await db
            .collection('USERS')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .limit(1)
            .get();

        if (existingQuery.docs.isNotEmpty) {
          _errorMessage = "Phone number already registered.";
          _isLoading = false;
          notifyListeners();
          return false;
        }
        String id=DateTime.now().millisecondsSinceEpoch.toString();

        // Create new user with controller values
        final newUser = {
          'id':id,
          "name": name,
          "phoneNumber": phoneNumber,
          "email": email,
          "password": password, // ❌ plain text (for demo only - **NEVER DO THIS in production**)
          "fcmToken": fcmToken, // ✅ ADDED FcmToken
          "createdAt": FieldValue.serverTimestamp(),
        };

        // Add new user to Firestore
        final doc = await db.collection('USERS').doc(id).set(newUser);

        // Update local user state
        _user = {...newUser, "id": id};

        // 💡 OPTIONAL: Clear controllers on success
        clearControllers();

        saveLoginState(_user!);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => UsersListScreen(userID: id, userName: name,from: 'Login22',

            ),
          ),
              (route) => false,
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        // Log the error for debugging
        print("Registration error: $e");
        _errorMessage = "Registration failed. Please try again."; // Simplified error message for the user
      }

      _isLoading = false;
      notifyListeners();
      return false;
    }
    Future<String?> getFcmToken() async {
      try {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        print("FCM Token: $fcmToken");
        return fcmToken;
      } catch (e) {
        print("Error getting FCM token: $e");
        return null;
      }
    }

    void clearControllers() {
      nameController.clear();
      phoneController.clear();
      emailController.clear();
      passwordController.clear();
    }  Future<void> saveLoginState(Map<String, dynamic> user) async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', user['id'] ?? '');
      await prefs.setString('userEmail', user['email'] ?? '');
      await prefs.setString('name', user['name'] ?? '');
      await prefs.setString('phone', user['phoneNumber'] ?? '');
      await prefs.setString('fcmToken', user['fcmToken'] ?? '');
    }

    Future<void> logout() async {
      _user = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userId');
      await prefs.remove('userEmail');
      await prefs.remove('name');
      await prefs.remove('phone');
      await prefs.remove('fcmToken');

      notifyListeners();
    }
  }
