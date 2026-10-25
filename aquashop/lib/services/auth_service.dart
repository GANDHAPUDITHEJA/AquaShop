import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();

  Future<void> signIn(String email, String pass) =>
      _auth.signInWithEmailAndPassword(email: email, password: pass);

  /// role: 'customer' | 'dealer'. Admins are set manually in Firestore.
  Future<void> register(
      String name, String email, String phone, String pass, String role) async {
    final c = await _auth.createUserWithEmailAndPassword(
        email: email, password: pass);
    await _db.collection('users').doc(c.user!.uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> roleOf(String uid) async {
    final d = await _db.collection('users').doc(uid).get();
    return (d.data()?['role'] ?? 'customer') as String;
  }

  Future<void> signOut() => _auth.signOut();
}
