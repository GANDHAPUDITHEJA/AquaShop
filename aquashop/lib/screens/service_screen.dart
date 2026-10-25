import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/address_picker.dart';
import '../services/notification_queue.dart';

const _types = [
  'Installation',
  'Repair',
  'Filter change',
  'Annual maintenance',
  'Other'
];
const _statuses = ['open', 'in_progress', 'resolved'];

/// Customer/dealer: raise + track requests. Admin: service desk for all requests.
class ServiceScreen extends StatelessWidget {
  final bool admin;
  const ServiceScreen({super.key, this.admin = false});

  Color _color(String s) => switch (s) {
        'resolved' => Colors.green.shade200,
        'in_progress' => Colors.blue.shade200,
        _ => Colors.orange.shade200,
      };

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance.collection('serviceRequests');
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final Query q = admin ? col : col.where('userId', isEqualTo: uid);
    return Scaffold(
      floatingActionButton: admin
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('New request'),
              onPressed: () => _newRequest(context)),
      body: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (_, s) {
          if (s.hasError) return Center(child: Text('${s.error}'));
          if (!s.hasData)
            return const Center(child: CircularProgressIndicator());
          int ts(QueryDocumentSnapshot d) =>
              ((d.data() as Map)['createdAt'] as Timestamp?)
                  ?.millisecondsSinceEpoch ??
              (1 << 50);
          final docs = [...s.data!.docs]
            ..sort((a, b) => ts(b).compareTo(ts(a)));
          if (docs.isEmpty)
            return const Center(child: Text('No service requests'));
          return ListView(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
              children: [
                for (final d in docs) _card(context, d),
              ]);
        },
      ),
    );
  }

  Widget _card(BuildContext context, QueryDocumentSnapshot d) {
    final m = d.data() as Map<String, dynamic>;
    final status = m['status'] as String;
    final note = (m['adminNote'] ?? '') as String;
    return Card(
      child: ListTile(
        isThreeLine: true,
        title: Text('${m['type']} • #${d.id.substring(0, 5)}'),
        subtitle: Text([
          if (admin) '${m['userEmail']} (${m['role']})',
          m['description'],
          '📍 ${m['address']}',
          if (note.isNotEmpty) 'Support: $note',
        ].join('\n')),
        trailing: Chip(
            label: Text(status.replaceAll('_', ' ')),
            backgroundColor: _color(status)),
        onTap: admin ? () => _respond(context, d, status, note) : null,
      ),
    );
  }

  void _newRequest(BuildContext context) {
    final desc = TextEditingController();
    PickedAddress? pickedAddress;
    var type = _types.first;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('New service request',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: type,
              items: [
                for (final t in _types)
                  DropdownMenuItem(value: t, child: Text(t))
              ],
              onChanged: (v) => set(() => type = v!),
              decoration: const InputDecoration(labelText: 'Service type'),
            ),
            TextField(
                controller: desc,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Describe the problem')),
            OutlinedButton.icon(
              icon: const Icon(Icons.map_outlined),
              label: Text(pickedAddress == null
                  ? 'Choose service address on map'
                  : 'Address selected'),
              onPressed: () async {
                final selected = await Navigator.push<PickedAddress>(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AddressPicker(title: 'Choose service address'),
                  ),
                );
                if (selected != null) set(() => pickedAddress = selected);
              },
            ),
            if (pickedAddress != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(pickedAddress!.address,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                if (desc.text.trim().isEmpty || pickedAddress == null) return;
                final u = FirebaseAuth.instance.currentUser!;
                final role = (await FirebaseFirestore.instance
                            .collection('users')
                            .doc(u.uid)
                            .get())
                        .data()?['role'] ??
                    'customer';
                final request = await FirebaseFirestore.instance
                    .collection('serviceRequests')
                    .add({
                  'userId': u.uid,
                  'userEmail': u.email,
                  'role': role,
                  'type': type,
                  'description': desc.text.trim(),
                  'address': pickedAddress!.address,
                  'latitude': pickedAddress!.latitude,
                  'longitude': pickedAddress!.longitude,
                  'status': 'open',
                  'adminNote': '',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                try {
                  await NotificationQueue.forUser(
                    userId: u.uid,
                    subject: 'AquaShop service request received',
                    body:
                        'Your ${type.toLowerCase()} request #${request.id.substring(0, 6)} was received.',
                  );
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Request submitted, but notification failed: $error')));
                  }
                }
              },
              child: const Text('Submit request'),
            ),
          ]),
        ),
      ),
    );
  }

  void _respond(BuildContext context, QueryDocumentSnapshot d, String status,
      String note) {
    final ctrl = TextEditingController(text: note);
    var st = status;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Update request'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              initialValue: st,
              items: [
                for (final s in _statuses)
                  DropdownMenuItem(
                      value: s, child: Text(s.replaceAll('_', ' ')))
              ],
              onChanged: (v) => set(() => st = v!),
            ),
            TextField(
                controller: ctrl,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Reply to customer')),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                await d.reference
                    .update({'status': st, 'adminNote': ctrl.text.trim()});
                final data = d.data() as Map<String, dynamic>;
                await NotificationQueue.forUser(
                  userId: data['userId'] as String,
                  subject: 'AquaShop service request $st',
                  body:
                      'Your service request #${d.id.substring(0, 6)} is now ${st.replaceAll('_', ' ')}.${ctrl.text.trim().isEmpty ? '' : '\nSupport: ${ctrl.text.trim()}'}',
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
