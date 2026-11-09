// upupa_frontend/lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/pages/login_screen.dart';
import 'features/auth/pages/register_screen.dart';
import 'features/auth/pages/mfa_setup_screen.dart';
import 'features/auth/pages/admin_users_screen.dart';
import 'features/auth/widgets/otp_login_form.dart';
import 'features/auth/services/auth_service.dart';
import 'features/collections/pages/collection_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AuthService().init();

  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: const UpupaApp(),
    ),
  );
}

class UpupaApp extends StatelessWidget {
  const UpupaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upupa',
      theme: ThemeData(primarySwatch: Colors.blue),

      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          if (authService.isAuthenticated) {
            return const CollectionListScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/collections': (context) => const CollectionListScreen(),

        '/otp-login': (context) => Scaffold(
          appBar: AppBar(title: const Text('ورود با کد یک‌بار مصرف')),
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: OtpLoginForm(
                  onLoginSuccess: () {
                    Navigator.pushReplacementNamed(context, '/collections');
                  },
                ),
              ),
            ),
          ),
        ),
        '/mfa-setup': (context) => const MfaSetupScreen(),
        '/admin/users': (context) => AdminUsersScreen(
          onImpersonateSuccess: () {
            Navigator.pushReplacementNamed(context, '/collections');
          },
        ),
      },
    );
  }
}
