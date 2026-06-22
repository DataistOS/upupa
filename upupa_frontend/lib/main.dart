// upupa_frontend/lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/pages/login_screen.dart';
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
    );
  }
}
