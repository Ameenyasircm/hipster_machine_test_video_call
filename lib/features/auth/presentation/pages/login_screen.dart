import 'package:flutter/material.dart';
import 'package:hipster_machine_test/core/utils/functions.dart';
import 'package:hipster_machine_test/features/auth/presentation/pages/registration_screen.dart';
import 'package:hipster_machine_test/features/auth/presentation/pages/users_list_screen.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../providers/login_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submitLogin(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<LoginProvider>(context, listen: false);
    await provider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),context
      );


    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LoginProvider>(context);

    // Define the colors for the gradient button
    const Color gradientStart = Color(0xFF00C6FF); // A bright teal/azure
    const Color gradientEnd = Color(0xFF8042F0);  // A deep purple

    return Scaffold(
      // 1. Dark background color from your splash screen
      backgroundColor: clDeepBlue,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 2. Butterfly Logo (Matching the splash screen style)
                // Assuming 'assets/AppLogoPng.png' is the butterfly/app logo
                Image.asset(
                  'assets/AppLogoPng.png',
                  height: 100, // Adjusted size
                ),

                const SizedBox(height: 24),

                // "Welcome Back" Text
                const Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: clCleanWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Log in to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: clLightSkyGray, // Lighter text for secondary line
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 40),

                // 3. Email Input Field (Clean White Design)
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: clDeepBlue), // Text inside field is dark
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: clDeepBlue.withOpacity(0.6)),
                    filled: true,
                    fillColor: clCleanWhite, // White background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none, // Remove border for clean look
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    // Use the vivid azure for icon color
                    prefixIcon: Icon(Icons.email_outlined, color: gradientStart),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email.';
                    if (!value.contains('@')) return 'Please enter a valid email.';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // 4. Password Input Field (Clean White Design)
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: clDeepBlue), // Text inside field is dark
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: clDeepBlue.withOpacity(0.6)),
                    filled: true,
                    fillColor: clCleanWhite, // White background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none, // Remove border for clean look
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    // Use the vivid azure for icon color
                    prefixIcon: Icon(Icons.lock_outline, color: gradientStart),
                    // Adding a trailing eye icon is common
                    suffixIcon: Icon(Icons.remove_red_eye_outlined, color: clDeepBlue.withOpacity(0.4)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password.';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // 5. Gradient Login Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [gradientStart, gradientEnd],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: provider.isLoading ? null : () => _submitLogin(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: provider.isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                              : const Text(
                            'LOG IN',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: clCleanWhite,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 6. Forgot Password and Sign Up Links
                // Align(
                //   alignment: Alignment.center,
                //   child: TextButton(
                //     onPressed: () {
                //       // Handle Forgot Password navigation
                //     },
                //     child: const Text(
                //       'Forgot Password?',
                //       style: TextStyle(color: clLightSkyGray, fontSize: 14),
                //     ),
                //   ),
                // ),

                const SizedBox(height: 4),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: clLightSkyGray, fontSize: 15),
                    ),
                    InkWell(
                      onTap: () {
                        callNext(const RegisterScreen(), context);
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: gradientStart, // Use a bright color for the link
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}