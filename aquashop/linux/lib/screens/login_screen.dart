import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController(), _email = TextEditingController(),
      _pass = TextEditingController();
  bool _register = false, _busy = false;
  String _role = 'customer';
  final _auth = AuthService();

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      _register
          ? await _auth.register(_name.text.trim(), _email.text.trim(), _pass.text, _role)
          : await _auth.signIn(_email.text.trim(), _pass.text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const SizedBox(height: 40),
            const Icon(Icons.water_drop, size: 72, color: Color(0xFF0288D1)),
            Text('AquaShop', textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 32),
            if (_register) TextField(controller: _name,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _email,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _pass, obscureText: true,
                decoration: const InputDecoration(labelText: 'Password')),
            if (_register) SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'customer', label: Text('Customer')),
                ButtonSegment(value: 'dealer', label: Text('Dealer')),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _busy ? null : _submit,
                child: Text(_register ? 'Create account' : 'Sign in')),
            TextButton(onPressed: () => setState(() => _register = !_register),
                child: Text(_register ? 'Have an account? Sign in' : 'New here? Register')),
          ]),
        ),
      );
}
