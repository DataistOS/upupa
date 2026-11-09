// upupa_frontend/lib/features/auth/pages/mfa_setup_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class MfaSetupScreen extends StatefulWidget {
  const MfaSetupScreen({Key? key}) : super(key: key);

  @override
  State<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends State<MfaSetupScreen> {
  final AuthService _authService = AuthService();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _mfaData;
  String? _errorMessage;
  bool _isVerified = false;

  Future<void> _handleSetupMfa() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _authService.setupMfa();
      setState(() {
        _mfaData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVerifyMfa() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _authService.currentUser?.email ?? 'user@example.com';
      await _authService.verifyMfa(email, _codeController.text.trim());

      setState(() {
        _isVerified = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('احراز هویت دو مرحله‌ای با موفقیت فعال شد.'),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات احراز هویت دو مرحله‌ای (MFA)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isVerified
            ? const Center(
                child: Text(
                  'حساب کاربری شما به MFA مجهز و امن است. ✅',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                children: [
                  const Text(
                    'با فعال‌سازی احراز هویت دو مرحله‌ای، امنیت حساب خود را افزایش دهید.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  if (_mfaData == null) ...[
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: _handleSetupMfa,
                            icon: const Icon(Icons.security),
                            label: const Text('شروع راه‌اندازی MFA'),
                          ),
                  ] else ...[
                    const Text(
                      '۱. این کلید را در اپلیکیشن Google Authenticator وارد کنید یا لینک زیر را اسکن کنید:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      'Secret: ${_mfaData!['secret']}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      'URL: ${_mfaData!['qr_code_url']}',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      '۲. کد ۶ رقمی تولید شده توسط اپلیکیشن را وارد کنید:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'کد ۶ رقمی تایید',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _handleVerifyMfa,
                            child: const Text('تایید و فعال‌سازی نهایی'),
                          ),
                  ],
                ],
              ),
      ),
    );
  }
}
