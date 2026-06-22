// upupa_frontend/lib/features/auth/pages/register_screen.dart
import 'dart:developer';
import 'package:flutter/material.dart';

import '../widgets/register_form.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLoading = false;

  Future<void> _handleRegisterSubmit(String email, String password) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().register(email, password);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/collections');
      }
    } catch (e) {
      log('Registration error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registration Failed: ${e.toString().split(':').last.trim()}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: RegisterForm(
              onRegisterSubmit: _handleRegisterSubmit,
              onNavigateToLogin: _navigateToLogin,
              isLoading: _isLoading,
            ),
          ),
        ),
      ),
    );
  }
}
