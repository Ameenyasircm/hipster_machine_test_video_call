// lib/core/utils/app_user.dart

class AppUser {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;

  AppUser({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
  });

  // Factory constructor to create an AppUser from a Firestore document
  factory AppUser.fromFirestore(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] ?? 'N/A', // Use default if field is missing
      phoneNumber: data['phoneNumber'] ?? 'N/A',
      email: data['email'] ?? 'N/A',
    );
  }
}