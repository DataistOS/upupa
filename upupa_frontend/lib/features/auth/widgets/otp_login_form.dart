// upupa_frontend/lib/features/auth/widgets/otp_login_form.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class OtpLoginForm extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const OtpLoginForm({super.key, required this.onLoginSuccess});

  @override
  State<OtpLoginForm> createState() => _OtpLoginFormState();
}

class _OtpLoginFormState extends State<OtpLoginForm> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _codeSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleRequestOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.requestOtp(_emailController.text.trim());
      setState(() {
        _codeSent = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد تایید به ایمیل شما ارسال شد.')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.authWithOtp(
        _emailController.text.trim(),
        _codeController.text.trim(),
      );
      setState(() {
        _isLoading = false;
      });
      widget.onLoginSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ورود بدون رمز (OTP)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),

          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'ایمیل',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !_codeSent,
          ),
          const SizedBox(height: 16),

          if (_codeSent) ...[
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'کد تایید ۶ رقمی',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
          ],

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _codeSent ? _handleVerifyOtp : _handleRequestOtp,
                  child: Text(_codeSent ? 'تایید و ورود' : 'دریافت کد تایید'),
                ),

          if (_codeSent)
            TextButton(
              onPressed: () {
                setState(() {
                  _codeSent = false;
                  _codeController.clear();
                });
              },
              child: const Text('تغییر ایمیل یا ارسال مجدد'),
            ),
        ],
      ),
    );
  }
}
