import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'screens/home_shells.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // run `flutterfire configure` first
  runApp(const AquaShop());
}

class AquaShop extends StatelessWidget {
  const AquaShop({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AquaShop',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF0288D1), useMaterial3: true),
        darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xFF0288D1),
            brightness: Brightness.dark, useMaterial3: true),
        home: const AuthGate(),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<User?>(
      stream: auth.authState,
      builder: (_, snap) {
        final user = snap.data;
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (user == null) return const LoginScreen();
        return FutureBuilder<String>(
          future: auth.roleOf(user.uid),
          builder: (_, r) {
            if (!r.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            switch (r.data) {
              case 'admin': return const AdminHome();
              case 'dealer': return const DealerHome();
              default: return const CustomerHome();
            }
          },
        );
      },
    );
  }
}
