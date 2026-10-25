import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/notification_queue.dart';

/// Customer/dealer: own order history. Admin: all orders + approve/reject.
class OrdersScreen extends StatelessWidget {
  final bool admin;
  const OrdersScreen({super.key, this.admin = false});

  Color _color(String s) => switch (s) {
        'approved' => Colors.green.shade200,
        'rejected' => Colors.red.shade200,
        _ => Colors.orange.shade200,
      };

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance.collection('orders');
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final Query q = admin ? col : col.where('userId', isEqualTo: uid);
    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (_, s) {
        if (s.hasError) return Center(child: Text('${s.error}'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        int ts(QueryDocumentSnapshot d) =>
            ((d.data() as Map)['createdAt'] as Timestamp?)
                ?.millisecondsSinceEpoch ??
            (1 << 50);
        final docs = [...s.data!.docs]..sort((a, b) => ts(b).compareTo(ts(a)));
        if (docs.isEmpty) return const Center(child: Text('No orders yet'));
        return ListView(padding: const EdgeInsets.all(8), children: [
          for (final d in docs) _card(context, d),
        ]);
      },
    );
  }

  Widget _card(BuildContext context, QueryDocumentSnapshot d) {
    final m = d.data() as Map<String, dynamic>;
    final status = m['status'] as String;
    return Card(
      child: ExpansionTile(
        title: Text(
            'Order #${d.id.substring(0, 6)} • ₹${(m['total'] as num).toStringAsFixed(0)}'),
        subtitle: admin ? Text('${m['userEmail']} (${m['role']})') : null,
        trailing: Chip(label: Text(status), backgroundColor: _color(status)),
        children: [
          for (final i in m['items'] as List)
            ListTile(
                dense: true,
                title: Text('${i['name']} × ${i['qty']}'),
                trailing: Text(
                    '₹${((i['unitPrice'] as num) * (i['qty'] as num)).toStringAsFixed(0)}')),
          ListTile(
              dense: true,
              leading: const Icon(Icons.payments_outlined),
              title: Text(
                  '${m['paymentMethod'] == 'cod' ? 'Cash on Delivery' : 'Razorpay'} • '
                  '${m['paymentStatus'] == 'paid' ? 'Paid' : 'Payment pending'}'),
              subtitle: m['paymentId'] == null
                  ? null
                  : Text('Payment ID: ${m['paymentId']}')),
          ListTile(
              dense: true,
              leading: const Icon(Icons.location_on_outlined),
              title: Text(m['address'] ?? '')),
          if (admin && status == 'pending')
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(
                    onPressed: () => _setStatus(d, 'rejected'),
                    child: const Text('Reject')),
                const SizedBox(width: 8),
                FilledButton(
                    onPressed: () => _setStatus(d, 'approved'),
                    child: const Text('Approve')),
              ]),
            ),
        ],
      ),
    );
  }

  Future<void> _setStatus(QueryDocumentSnapshot d, String status) async {
    await d.reference.update({'status': status});
    final data = d.data() as Map<String, dynamic>;
    await NotificationQueue.forUser(
      userId: data['userId'] as String,
      subject: 'AquaShop order $status',
      body: 'Your order #${d.id.substring(0, 6)} has been $status.',
    );
  }
}
