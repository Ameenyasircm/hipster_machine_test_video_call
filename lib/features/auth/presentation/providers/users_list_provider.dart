import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_model.dart';

class UserListProvider extends ChangeNotifier {
  List<UserModel> usersList = [];

  Future<void> fetchUsers() async {
    final response = await http.get(
      Uri.parse('https://reqres.in/api/users?page=1'),
    );

    if (response.statusCode == 200) {
      log(response.body);

      final Map<String, dynamic> jsonMap = json.decode(response.body);
      final List<dynamic> jsonList = jsonMap['data'];

      // Map JSON to UserModel and assign to usersList
      usersList = jsonList.map((e) => UserModel.fromJson(e)).toList();

      notifyListeners(); // if using Provider to update UI
    } else {
      throw Exception('Failed to load users');
    }
  }


}
