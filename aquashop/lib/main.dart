import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'screens/home_shells.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions
          .currentPlatform); // run `flutterfire configure` first
  runApp(const AquaShop());
}

class AquaShop extends StatelessWidget {
  const AquaShop({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AquaShop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0077B6),
            brightness: Brightness.light,
            surface: const Color(0xFFF7FAFC),
          ),
          scaffoldBackgroundColor: const Color(0xFFF7FAFC),
          useMaterial3: true,
          fontFamily: 'sans',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF7FAFC),
            foregroundColor: Color(0xFF102A43),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
              side: BorderSide(color: Color(0xFFE6EEF4)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9E5EC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9E5EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF0077B6), width: 2),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 50),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            height: 72,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFD7F0FA),
            labelTextStyle: WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF35B8E8),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        themeMode: ThemeMode.light,
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
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (user == null) return const LoginScreen();
        return FutureBuilder<String>(
          future: auth.roleOf(user.uid),
          builder: (_, r) {
            if (!r.hasData) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            switch (r.data) {
              case 'admin':
                return const AdminHome();
              case 'dealer':
                return const DealerHome();
              default:
                return const CustomerHome();
            }
          },
        );
      },
    );
  }
}
