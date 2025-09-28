import 'package:flutter/material.dart';
import 'package:hipster_machine_test/core/utils/functions.dart';
import 'package:hipster_machine_test/features/auth/presentation/pages/registration_screen.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../providers/login_provider.dart'; // adjust path

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
      bool success = await provider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success) {
        // Navigate to User List Screen or Video Call Screen
        Navigator.pushReplacementNamed(context, '/users');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Login failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LoginProvider>(context);

    return Scaffold(
      backgroundColor: clLightSkyGray,
      appBar: AppBar(
        title: const Text('Machine Test Login'),
        backgroundColor: clDeepBlue,
        foregroundColor: clCleanWhite,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(Icons.lock_open, size: 80, color: clDeepBlue),
                const SizedBox(height: 48),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email, color: clVividAzure.withOpacity(0.7)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email.';
                    if (!value.contains('@')) return 'Please enter a valid email.';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: clVividAzure.withOpacity(0.7)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password.';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Login button
                ElevatedButton(
                  onPressed: provider.isLoading ? null : () => _submitLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: clVividAzure,
                    foregroundColor: clCleanWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: provider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login & Start Assessment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 20,),
                InkWell(
                  onTap: (){
                    callNext(RegisterScreen(), context);
                  },
                  child: Align(
                      alignment:Alignment.bottomCenter,
                      child: Text('Register Now',style: TextStyle(color: Colors.blue,fontSize: 17),)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
