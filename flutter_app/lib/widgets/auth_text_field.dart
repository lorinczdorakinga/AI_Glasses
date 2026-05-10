import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool obscure;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.validator,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:  widget.controller,
      obscureText: _obscure,
      validator:   widget.validator,
      decoration: InputDecoration(
        labelText:  widget.label,
        prefixIcon: Icon(widget.icon),
        border:     OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled:     true,
        fillColor:  Colors.grey.shade50,
        // Eye icon only shows on password fields
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}