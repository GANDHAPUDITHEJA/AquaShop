import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationQueue {
  static final _db = FirebaseFirestore.instance;

  static Future<void> forUser({
    required String userId,
    required String subject,
    required String body,
  }) async {
    final user = await _db.collection('users').doc(userId).get();
    final data = user.data() ?? {};
    final email = data['email'] as String?;
    final phone = data['phone'] as String?;
    final batch = _db.batch();

    if (email != null && email.isNotEmpty) {
      batch.set(_db.collection('mail').doc(), {
        'to': [email],
        'message': {'subject': subject, 'text': body},
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    if (phone != null && phone.isNotEmpty) {
      batch.set(_db.collection('messages').doc(), {
        'to': phone,
        'body': body,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    if (email != null && email.isNotEmpty ||
        phone != null && phone.isNotEmpty) {
      await batch.commit();
    }
  }
}
