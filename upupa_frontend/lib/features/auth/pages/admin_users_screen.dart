// upupa_frontend/lib/features/auth/pages/admin_users_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminUsersScreen extends StatefulWidget {
  final VoidCallback onImpersonateSuccess;

  const AdminUsersScreen({super.key, required this.onImpersonateSuccess});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  final _mockUsers = [
    {'id': 'user_01', 'email': 'alice@example.com'},
    {'id': 'user_02', 'email': 'bob@example.com'},
    {'id': 'user_03', 'email': 'charlie@example.com'},
  ];

  Future<void> _handleImpersonate(String userId, String email) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.impersonate(userId);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('شما اکنون به عنوان $email وارد شده‌اید.')),
      );

      widget.onImpersonateSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت کاربران و جعل هویت (Impersonation)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'به عنوان مدیر سیستم، می‌توانید جهت عیب‌یابی به حساب هر کاربر وارد شوید:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _mockUsers.length,
                  itemBuilder: (context, index) {
                    final user = _mockUsers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(user['email']!),
                        subtitle: Text('ID: ${user['id']}'),
                        trailing: ElevatedButton(
                          onPressed: () =>
                              _handleImpersonate(user['id']!, user['email']!),
                          child: const Text('ورود به عنوان کاربر'),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
