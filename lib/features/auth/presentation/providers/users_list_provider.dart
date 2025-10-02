import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/signaling_service.dart';
import '../../data/models/registered_members_model.dart';
import '../../data/models/user_model.dart';

class UserListProvider extends ChangeNotifier {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  List<UserModel> usersList = [];

  Future<void> fetchUsers() async {
    final response = await http.get(
      Uri.parse('https://jsonplaceholder.typicode.com/users'),
      headers: {
        "Accept": "application/json",
      },
    );

    print('${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);

      usersList = jsonList.map((e) => UserModel.fromJson(e)).toList();

      notifyListeners();
    } else {
      print("Response body: ${response.body}");
      throw Exception('Failed to load users - ${response.statusCode}');
    }
  }

  List<AppUser> _registeredUsers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AppUser> get registeredUsers => _registeredUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 2. FUNCTION NAME CHANGED
  Future<void> fetchRegisteredUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot = await db.collection('USERS').get();

      // Convert the Firestore documents into a list of AppUser objects
      // 3. INTERNAL LIST REFERENCE CHANGED
      _registeredUsers = querySnapshot.docs.map((doc) {
        return AppUser.fromFirestore(doc.id, doc.data());
      }).toList();
      print(_registeredUsers.length.toString()+' FJMRFRFRF ');
    } catch (e) {
      _errorMessage = "Failed to fetch registered users: $e";
      print("Error fetching registered users: $e");
    }



    _isLoading = false;
    notifyListeners();
  }



}
