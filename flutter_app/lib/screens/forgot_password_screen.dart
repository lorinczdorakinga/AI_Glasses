import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Steps: 1 = enter email, 2 = enter code + new password, 3 = success
  int  _step    = 1;
  bool _loading = false;

  final _emailController    = TextEditingController();
  final _codeController     = TextEditingController();
  final _newPassController  = TextEditingController();
  final _confirmController  = TextEditingController();
  final _formKey1           = GlobalKey<FormState>();
  final _formKey2           = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPassController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Step 1 — request code
  Future<void> _sendCode() async {
    if (!_formKey1.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body:    jsonEncode({'email': _emailController.text.trim()}),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() => _step = 2);
      } else {
        final body = jsonDecode(res.body);
        _showError(body['error'] ?? 'Something went wrong');
      }
    } catch (_) {
      _showError('Could not connect to server');
    } finally {
      setState(() => _loading = false);
    }
  }

  // Step 2 — verify code and reset
  Future<void> _resetPassword() async {
    if (!_formKey2.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email':        _emailController.text.trim(),
          'code':         _codeController.text.trim(),
          'new_password': _newPassController.text,
        }),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() => _step = 3);
      } else {
        final body = jsonDecode(res.body);
        _showError(body['error'] ?? 'Something went wrong');
      }
    } catch (_) {
      _showError('Could not connect to server');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: switch (_step) {
              1 => _buildStep1(),
              2 => _buildStep2(),
              _ => _buildSuccess(),
            },
          ),
        ),
      ),
    );
  }

  // Step 1 UI — enter email
  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: Column(
        children: [
          const Icon(Icons.lock_reset, size: 72, color: Colors.indigo),
          const SizedBox(height: 16),
          Text('Forgot password?',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Enter your email and we\'ll send you a 6-digit reset code.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          AuthTextField(
            label:      'Email',
            icon:       Icons.email_outlined,
            controller: _emailController,
            validator:  (v) => v!.contains('@') ? null : 'Enter a valid email',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _sendCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send Code', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2 UI — enter code + new password
  Widget _buildStep2() {
    return Form(
      key: _formKey2,
      child: Column(
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 72, color: Colors.indigo),
          const SizedBox(height: 16),
          Text('Check your email', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'We sent a 6-digit code to ${_emailController.text}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          // Code input
          TextFormField(
            controller:  _codeController,
            keyboardType: TextInputType.number,
            textAlign:   TextAlign.center,
            maxLength:   6,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: InputDecoration(
              hintText:    '000000',
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled:     true,
              fillColor:  Colors.grey.shade50,
            ),
            validator: (v) => v!.length == 6 ? null : 'Enter the 6-digit code',
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label:      'New Password',
            icon:       Icons.lock_outlined,
            controller: _newPassController,
            obscure:    true,
            validator:  (v) => v!.length >= 6 ? null : 'At least 6 characters',
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label:      'Confirm New Password',
            icon:       Icons.lock_outlined,
            controller: _confirmController,
            obscure:    true,
            validator:  (v) => v == _newPassController.text ? null : 'Passwords do not match',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Reset Password', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _step = 1),
            child: const Text('Resend code'),
          ),
        ],
      ),
    );
  }

  // Step 3 UI — success
  Widget _buildSuccess() {
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
        const SizedBox(height: 16),
        const Text('Password updated!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'You can now log in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Back to Login', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}