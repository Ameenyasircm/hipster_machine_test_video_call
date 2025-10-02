
The  app allows a new user to register with their name, phone number, email, and password. Once registered, the user can log in using their credentials. After login, the app fetches and displays a list of sample users from an API. A floating action button is available for initiating a video call. When the user taps the button, all registered members are shown, and the logged-in user can select any member to start a one-to-one video call. The video call screen shows both the local camera stream and the remote participant’s video, with options to mute/unmute audio and enable/disable video during the call.
🚀 Features

User Registration

Register with Name, Phone, Email, and Password.

Data stored securely in Firebase.

User Authentication

Login using registered email & password.

Basic validation for empty fields & email format.

User List (REST API Integration)

Fetches a list of sample users from a fake REST API.

Fetches registered users from a Firebase.

Displays in a scrollable list with user details.

Video Call (RTC SDK Integration)

Floating Action Button for starting a call.

Displays all registered members.

One-to-one video calling between logged-in users.

Supports:

Local & remote video streams

Mute/Unmute microphone

Enable/Disable camera

Splash screen & app icon.

Android permissions (Camera, Microphone, Internet).

Versioning & signing (debug keys).
