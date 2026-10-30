// upupa_frontend/lib/features/auth/pages/login_screen.dart
import 'dart:developer';
import 'package:flutter/material.dart';

import '../widgets/login_form.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleLoginSubmit(String email, String password) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().login(email, password);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/collections');
      }
    } catch (e) {
      log('Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Login Failed: ${e.toString().split(':').last.trim()}',
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

  void _navigateToRegister() {
    Navigator.of(context).pushReplacementNamed('/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: LoginForm(
              onLoginSubmit: _handleLoginSubmit,
              onNavigateToRegister: _navigateToRegister,
              isLoading: _isLoading,
            ),
          ),
        ),
      ),
    );
  }
}
