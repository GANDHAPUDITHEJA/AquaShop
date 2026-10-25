import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static bool _started = false;

  /// Saves this device's FCM token on the user doc and shows foreground messages.
  static Future<void> init(void Function(String title, String body) onForeground) async {
    if (kIsWeb || _started) return; // web push needs extra setup; skipped
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _started = true;
    final fm = FirebaseMessaging.instance;
    await fm.requestPermission();
    Future<void> save(String? t) async {
      if (t == null) return;
      await FirebaseFirestore.instance
          .collection('users').doc(uid).set({'fcmToken': t}, SetOptions(merge: true));
    }
    await save(await fm.getToken());
    fm.onTokenRefresh.listen(save);
    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      if (n != null) onForeground(n.title ?? '', n.body ?? '');
    });
  }

  static void reset() => _started = false; // call on logout
}
