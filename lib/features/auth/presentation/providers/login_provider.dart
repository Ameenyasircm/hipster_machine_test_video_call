  import 'dart:collection';
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

    Future<bool> login(String email, String password) async {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      try {
        final querySnapshot = await db
            .collection('USERS')
            .where('email', isEqualTo: email)
            .where('password', isEqualTo: password)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          _user = querySnapshot.docs.first.data();

          // ✅ Save login state locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userEmail', email);

          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = "Invalid email or password";
        }
      } catch (e) {
        _errorMessage = "Login failed: $e";
        print(e.toString()+' EJFMJRKF ');
      }

      _isLoading = false;
      notifyListeners();
      return false;
    }

    Future<bool> register(String email, String password) async {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      try {
        // Check if user already exists
        final existing = await db
            .collection('USERS')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) {
          _errorMessage = "Email already registered.";
          _isLoading = false;
          notifyListeners();
          return false;
        }

        // Create new user
        final newUser = {
          "email": email,
          "password": password, // ❌ plain text (for demo only)
          "createdAt": FieldValue.serverTimestamp(),
        };

        final doc = await db.collection('USERS').add(newUser);
        _user = {...newUser, "id": doc.id};

        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        _errorMessage = "Registration failed: $e";
      }

      _isLoading = false;
      notifyListeners();
      return false;
    }
    Future<void> saveLoginState(String email) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', email);
    }
    Future<void> logout() async {
      _user = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userEmail');
      notifyListeners();
    }
  }
