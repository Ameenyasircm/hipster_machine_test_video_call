import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_model.dart';

class UserListProvider extends ChangeNotifier {
  List<UserModel> usersList = [];

  Future<void> fetchUsers() async {
    final response = await http.get(
      Uri.parse('https://jsonplaceholder.typicode.com/users'),
    );


    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);

      // Map JSON to UserModel and assign to usersList
      usersList = jsonList.map((e) => UserModel.fromJson(e)).toList();

      notifyListeners(); // if using Provider to update UI
    } else {
      throw Exception('Failed to load users');
    }
  }


}
