import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../providers/users_list_provider.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserListProvider>(context);

    return Scaffold(
      backgroundColor: clLightSkyGray,
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: clDeepBlue,
        foregroundColor: clCleanWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              provider.fetchUsers();
            },
          ),
        ],
      ),
      body:
      FutureBuilder(
        future: provider.fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              provider.usersList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (provider.usersList.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.usersList.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final user = provider.usersList[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user.avatar), // ✅ avatar from API
                ),
                title: Text(
                  user.fullName, // ✅ uses getter → "$firstName $lastName"
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(user.email),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16), // optional
              );
            },
          );
        },
      )
,
    );
  }
}
