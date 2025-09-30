import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? phone;    // <--- ADDED: Must be nullable
  final String? website;  // <--- ADDED: Must be nullable

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.phone,   // <--- Updated constructor
    this.website, // <--- Updated constructor
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      // Safely access nullable fields. If the key is missing or null, Dart's
      // safe access operator (as String?) handles it correctly.
      phone: json['phone'] as String?,
      website: json['website'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "username": username,
      "email": email,
      "phone": phone,
      "website": website,
    };
  }
}



class Address {
  final String street;
  final String suite;
  final String city;
  final String zipcode;
  final Geo geo;

  Address({
    required this.street,
    required this.suite,
    required this.city,
    required this.zipcode,
    required this.geo,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      suite: json['suite'],
      city: json['city'],
      zipcode: json['zipcode'],
      geo: Geo.fromJson(json['geo']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "street": street,
      "suite": suite,
      "city": city,
      "zipcode": zipcode,
      "geo": geo.toJson(),
    };
  }
}

class Geo {
  final String lat;
  final String lng;

  Geo({required this.lat, required this.lng});

  factory Geo.fromJson(Map<String, dynamic> json) {
    return Geo(
      lat: json['lat'],
      lng: json['lng'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "lat": lat,
      "lng": lng,
    };
  }
}
class Company {
  final String name;
  final String catchPhrase;
  final String bs;

  Company({
    required this.name,
    required this.catchPhrase,
    required this.bs,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'],
      catchPhrase: json['catchPhrase'],
      bs: json['bs'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "catchPhrase": catchPhrase,
      "bs": bs,
    };
  }
}

class Booking {
  final String id;
  final String userId;
  final String conferenceId;
  final DateTime bookedAt;
  final DateTime endAt;
  final bool isCalled;
  final String name; // Non-required
  final int tokenNumber;
  final String bookingDescription;
  final String bookedUserFCM;
  final String phone; // Non-required
  final String address; // Non-required
  final String pinCode; // Non-required
  final String aadharNumber; // Non-required
  final String panchayat; // Non-required
  final String ward; // Non-required

  Booking({
    required this.id,
    required this.userId,
    required this.conferenceId,
    required this.bookedAt,
    required this.endAt,
    this.isCalled = false,
    this.name = '', // Default to empty string
    required this.tokenNumber,
    required this.bookingDescription,
    required this.bookedUserFCM,
    this.phone = '', // Default to empty string
    this.address = '', // Default to empty string
    this.pinCode = '', // Default to empty string
    this.aadharNumber = '', // Default to empty string
    this.panchayat = '', // Default to empty string
    this.ward = '', // Default to empty string
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'conferenceId': conferenceId,
      'bookedAt': Timestamp.fromDate(bookedAt),
      'endAt': Timestamp.fromDate(endAt),
      'isCalled': isCalled,
      'name': name,
      'tokenNumber': tokenNumber,
      'bookingDescription': bookingDescription,
      'bookedUserFCM': bookedUserFCM,
      'phone': phone,
      'address': address,
      'pinCode': pinCode,
      'aadharNumber': aadharNumber,
      'panchayat': panchayat,
      'ward': ward,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map, String id) {
    return Booking(
      id: id,
      userId: map['userId'] ?? '',
      conferenceId: map['conferenceId'] ?? '',
      bookedAt: (map['bookedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endAt: (map['endAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCalled: map['isCalled'] ?? false,
      name: map['name'] ?? '',
      tokenNumber: map['tokenNumber'] ?? 0,
      bookingDescription: map['bookingDescription'] ?? '',
      bookedUserFCM: map['bookedUserFCM'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      pinCode: map['pinCode'] ?? '',
      aadharNumber: map['aadharNumber'] ?? '',
      panchayat: map['panchayat'] ?? '',
      ward: map['ward'] ?? '',
    );
  }
}