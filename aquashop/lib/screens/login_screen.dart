import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _phone = TextEditingController(),
      _pass = TextEditingController();
  bool _register = false, _busy = false;
  String _role = 'customer';
  final _auth = AuthService();

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      _register
          ? await _auth.register(_name.text.trim(), _email.text.trim(),
              _phone.text.trim(), _pass.text, _role)
          : await _auth.signIn(_email.text.trim(), _pass.text);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.water_drop_rounded,
                              color: Colors.white, size: 42),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: Text('AquaShop',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF102A43))),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                            _register
                                ? 'Create your account'
                                : 'Pure water. Better living.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: Colors.blueGrey)),
                      ),
                      const SizedBox(height: 32),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(children: [
                            if (_register) ...[
                              TextField(
                                  controller: _name,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                      labelText: 'Full name',
                                      prefixIcon: Icon(Icons.person_outline))),
                              const SizedBox(height: 14),
                            ],
                            TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                    labelText: 'Email address',
                                    prefixIcon: Icon(Icons.email_outlined))),
                            if (_register) ...[
                              const SizedBox(height: 14),
                              TextField(
                                  controller: _phone,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                      labelText:
                                          'Phone number (for SMS updates)',
                                      prefixIcon: Icon(Icons.phone_outlined))),
                            ],
                            const SizedBox(height: 14),
                            TextField(
                                controller: _pass,
                                obscureText: true,
                                decoration: const InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(Icons.lock_outline))),
                            if (_register) ...[
                              const SizedBox(height: 18),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Account type',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(
                                        value: 'customer',
                                        label: Text('Customer')),
                                    ButtonSegment(
                                        value: 'dealer', label: Text('Dealer')),
                                  ],
                                  selected: {_role},
                                  onSelectionChanged: (s) =>
                                      setState(() => _role = s.first),
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _busy ? null : _submit,
                                child: _busy
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : Text(_register
                                        ? 'Create account'
                                        : 'Sign in'),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              setState(() => _register = !_register),
                          child: Text(_register
                              ? 'Already have an account? Sign in'
                              : 'New here? Create an account'),
                        ),
                      ),
                    ]),
              ),
            ),
          ),
        ),
      );
}
