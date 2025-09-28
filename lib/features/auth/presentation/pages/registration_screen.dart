import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../providers/login_provider.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submitRegister(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<LoginProvider>(context, listen: false);
      bool success = await provider.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success) {
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

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                value != null && value.contains('@') ? null : 'Invalid email',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) =>
                value != null && value.length >= 6 ? null : 'Min 6 chars',
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: provider.isLoading ? null : () => _submitRegister(context),
                child: provider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
