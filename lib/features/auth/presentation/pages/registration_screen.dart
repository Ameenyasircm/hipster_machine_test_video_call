import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../providers/login_provider.dart';
import 'package:provider/provider.dart';

// --- Custom Widgets for Theme ---

class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const GradientButton({Key? key, required this.child, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        gradient: onPressed != null
            ? const LinearGradient(
          colors: [Color(0xFF4C8DFF), Color(0xFFC04CFF)], // Blue to Purple gradient
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        )
            : null, // No gradient when disabled
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class ThemedTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const ThemedTextFormField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.validator,
    this.keyboardType = TextInputType.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white), // Input text color
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70), // Label color
        filled: true,
        fillColor: Colors.white.withOpacity(0.1), // Slightly transparent dark fill
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none, // No border for a clean look
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Color(0xFFC04CFF), width: 2), // Highlight border
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}

// --- RegisterScreen ---

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  // Added controllers for Name and Phone Number
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submitRegister(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<LoginProvider>(context, listen: false);

      // Pass all four fields to the new register method
      bool success = await provider.register(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success) {
        // Assuming '/users' is the main screen after successful registration
        Navigator.pushReplacementNamed(context, '/users');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Registration failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LoginProvider>(context);

    // Set the dark background theme color
    const darkBackgroundColor = Color(0xFF0F1828);
    // const darkBackgroundColor = Color(0xFF0E1428); // Based on the image's dark navy

    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        title: const Text('Sign Up', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent, // Transparent app bar
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Butterfly Logo (as seen in the login image)
              const Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Icon(
                  CupertinoIcons.heart_fill, // Using a simple icon for the butterfly placeholder
                  // You should replace this with a proper asset/SVG for the butterfly
                  size: 60,
                  color: Color(0xFFC04CFF), // Purple part of the gradient
                ),
              ),

              // Title and Subtitle
              const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join us to continue',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Name Field
              ThemedTextFormField(
                controller: _nameController,
                labelText: 'Full Name',
                validator: (value) =>
                value != null && value.isNotEmpty ? null : 'Name is required',
              ),
              const SizedBox(height: 16),

              // Phone Number Field
              ThemedTextFormField(
                controller: _phoneController,
                labelText: 'Phone Number',
                keyboardType: TextInputType.phone,
                validator: (value) =>
                value != null && value.length >= 10 ? null : 'Invalid phone number',
              ),
              const SizedBox(height: 16),

              // Email Field
              ThemedTextFormField(
                controller: _emailController,
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                value != null && value.contains('@') ? null : 'Invalid email',
              ),
              const SizedBox(height: 16),

              // Password Field
              ThemedTextFormField(
                controller: _passwordController,
                labelText: 'Password',
                obscureText: true,
                validator: (value) =>
                value != null && value.length >= 6 ? null : 'Password must be min 6 characters',
              ),
              const SizedBox(height: 40),

              // Gradient Register Button
              GradientButton(
                onPressed: provider.isLoading ? null : () => _submitRegister(context),
                child: provider.isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : const Text(
                  "SIGN UP",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Back to Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.white70),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Go back to the login screen
                    },
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: Color(0xFF4C8DFF), // Blue part of the gradient for link
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
    );
  }
}