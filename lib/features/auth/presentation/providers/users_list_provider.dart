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


}
