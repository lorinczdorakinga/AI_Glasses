import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import 'goal_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _name     = TextEditingController();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  final _confirm  = TextEditingController();

  @override
  void dispose() {
    _name.dispose(); _email.dispose();
    _password.dispose(); _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth    = context.read<AuthProvider>();
    final success = await auth.register(_name.text.trim(), _email.text.trim(), _password.text);
    if (!mounted) return;
    if (success) {
Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GoalScreen()));    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Registration failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 16),
                AuthTextField(
                  label:      'Full Name',
                  icon:       Icons.person_outline,
                  controller: _name,
                  validator:  (v) => v!.isNotEmpty ? null : 'Name is required',
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label:      'Email',
                  icon:       Icons.email_outlined,
                  controller: _email,
                  validator:  (v) => v!.contains('@') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label:      'Password',
                  icon:       Icons.lock_outlined,
                  controller: _password,
                  obscure:    true,
                  validator:  (v) => v!.length >= 6 ? null : 'At least 6 characters',
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label:      'Confirm Password',
                  icon:       Icons.lock_outlined,
                  controller: _confirm,
                  obscure:    true,
                  validator:  (v) => v == _password.text ? null : 'Passwords do not match',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Account', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}