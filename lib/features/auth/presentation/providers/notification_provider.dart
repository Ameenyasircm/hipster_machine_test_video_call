import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/cupertino.dart' show ChangeNotifier, BuildContext;
class NotificationProvider extends ChangeNotifier{
  Future<void> sendPushNotification( String title, String subTitle, BuildContext context,String token) async {
    print(token+"dhbhbhbhdb");
    String postUrl = 'https://fcm.googleapis.com/v1/projects/nammude-vadakara/messages:send';
    String serverKey = await getAccessToken(); // Obtain access token

    // for (String token in fcmList) {
    //   print("$token  ............");

    final Map<String, dynamic> message = {
      "message": {
        "token": token,
        "notification": {
          "title": title,
          "body": subTitle,
          // "image":image,
        },
        "data": {
          // "image_url": image,
          "title": title,
          "body": subTitle,
        },
        "android": {
          "notification": {
            "click_action": "",
            // "image": image
          },
          "priority": "high"
        },
        "apns": {
          "payload": {
            "aps": {
              "alert": {
                "title": title,
                "body": subTitle,
              },
              "mutable-content": 1,
              "content-available": 1,
            },
            "fcm_options": {
              // "image": image,
            }
          }
        }
      }
    };

    http.Response response = await http.post(
      Uri.parse(postUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKey',  // Use the retrieved access token
      },
      body: json.encode(message),
    );

    print('FCM Response: ${response.body}');
    print('FCM Response Code: ${response.statusCode}');
  }


  Future<String> getAccessToken() async {
    print('Starting access token fetch...');

    // New service account JSON
    final serviceAccountJson = json.decode(r'''
{
  "type": "service_account",
  "project_id": "hipster-machine-test",
  "private_key_id": "a7b486e82f80ac1db0bd78d3fdade82017a89deb",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCuGGT+VIwso2GY\n887fCQiwl6XBOs/fhj1fq4FU94Fz9EfRDGWFKpL5YspHQurWlwOsvCQ4EsBIhBFc\ngruQKePGlemYCNdxMvYnFP9Oe6zpMPodmcOGyso3bF3uQhNwQY935xui2PXPeHDg\nhXEeQMH83jd93ujJWAoYGoj98lNofiJlApBM88817JccxAYjp+/fpQ9ENfoLH9/i\n04oHTEzXIVBxGN0acduucpQwhnQ9mX1EZfVDm4Pj3aKJyyPuoYP10z3CWSpBHhxt\nuJoRPT8xO9oOJnTmBnhA5SV4No9o8wf3d1JkXl3B7Wp2VjZ225R4xR8aPp1z20gU\n+04AHgfzAgMBAAECggEAEfoB363SRZUJ8bW8gZTuDpyyExL5aP7JspRuh9wAxCeQ\nDNrSAXSlICwzxTT4iSJR0Px3uZ8yDKrachTWZ5XzvPXjh3045dREd5ei9IiFERUr\na8gMrmFH4n4wRXcRiRtemZvFuO8x6Ujp+ue8h5+vMucCkDQ8EaJOHzFfk5KkoIWN\n+sC0bkxDd6pg0mEzdfRiOGBYn4KnVmjU49HFGCYEn8Re2gvkdLHeNoKVyjkT9H7d\n/64M1FuJbUW1RMHxagjEaujF2OEtinMurCcaRyFTPI2tpmi+KbhlmvnXvgiNqNQp\n6DRPXh4JJJwSsf7Z6LRSf0ja/Ff1h5aFj0OiUendGQKBgQDmZ3cIiEZ+rnybTQvd\nbmzGNnTl3YF9esf49TnhVeY86QZ1XGjTbXC+sajGpyZ6hkLtdPZRcnur+dZfUy8U\nSqvL3WelWCMJA2fDdbHhzlUICi2/dP91rlmPiNM5oAqOUa1m+KLxbUs0pBCg3PTr\n04UfufSbpOtO5+w2VuHbPNVjywKBgQDBb4tSVwoE1AK4Iwt1tFXbi5iypx/3cE0v\nV1Jqj4yoOmHm3JIVN4Spy1VlUrDUaczcnyt6CZcdtf6q18MzuX2eLoFx559P5JO4\n77zIwkg7eEDlLE7EDzuyluoKXXXD0UmSu3jNi6RhCTyxdhByXqfJ4ictbqtisGzM\nDkQPbsv3eQKBgAqD6FPUXFtFvVwdHRCDDKXTMGyZOmKuqte64WReVj6rZ+cNS59y\nnDWnyAsg78mhvQY3U1KORgSoR1dcZYaojcSlGyjZp+euZxrtkSu8Dfdq94GIZmxJ\ng77gQLudiT3Ljn1nlZAtK8SARF4DF453vdif1QEResfEH+yu9GncEeUXAoGAd8GV\nIc8dNswDOvkHWUHifd+5E7IASnLOdma7cZmZ3XT3s7QPBO+wRGbMYcSGEZvG5zfr\n9MwHMK/CEQcvpNBMAyiLn3dk3FOJWU+jMy+FBLx4gOmjgiJkNTbVgsFF7Yue3ycN\nrUOs6x6K4ttTZ1tOyeAnnSsNFDZhxRt3644O3RECgYBhbHs78u01VVq2WputsuGG\n65OTPqg6MyBcm+48SrcDToUv+z+amcMV4SJFCz63jQ3Xzk6HdahehYnRrj7/BqQ+\ngGZhhRo20xJET/TLgV3WmV8qwxjTUMLC8HV5duYAz4U+mx55ORqYCg/pBuThSY0M\nepJwmk7oESI+56v3jUKbEw==\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@hipster-machine-test.iam.gserviceaccount.com",
  "client_id": "101726008404801429709",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40hipster-machine-test.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
  ''');

    List<String> scopes = [
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    http.Client client = http.Client();

    try {
      // Authenticate with service account
      final credentials = auth.ServiceAccountCredentials.fromJson(serviceAccountJson);
      final authenticatedClient = await auth.clientViaServiceAccount(credentials, scopes);

      // Extract access token
      final accessToken = authenticatedClient.credentials.accessToken.data;
      print("Access token: $accessToken");

      // Cleanup
      authenticatedClient.close();
      client.close();

      return accessToken;
    } catch (e) {
      client.close();
      print("Error fetching access token: $e");
      rethrow;
    }
  }


}