import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/cart.dart';
import '../services/pricing.dart';
import '../services/razorpay_service.dart';
import '../widgets/address_picker.dart';
import '../services/notification_queue.dart';

class CartScreen extends StatelessWidget {
  final String role;
  const CartScreen({super.key, required this.role});

  Future<void> _checkout(BuildContext context) async {
    final cart = Cart.instance;
    for (final i in cart.items.values) {
      final err = Pricing.validateQty(role, i.qty);
      if (err != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${i.product.name}: $err')));
        return;
      }
    }
    final pickedAddress = await Navigator.push<PickedAddress>(
      context,
      MaterialPageRoute(
          builder: (_) =>
              const AddressPicker(title: 'Choose delivery address')),
    );
    if (pickedAddress == null) return;
    final user = FirebaseAuth.instance.currentUser!;
    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose payment method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Pay online with Razorpay'),
              subtitle: const Text('Secure online payment'),
              onTap: () => Navigator.pop(dialogContext, 'razorpay'),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay when your order arrives'),
              onTap: () => Navigator.pop(dialogContext, 'cod'),
            ),
          ],
        ),
      ),
    );
    if (paymentMethod == null) return;

    var paymentStatus = 'pending';
    String? paymentId;
    if (paymentMethod == 'razorpay') {
      final pay = await payWithRazorpay(
          amount: cart.total(role), email: user.email ?? '');
      if (pay.status != PayStatus.paid) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(pay.status == PayStatus.unsupported
                  ? 'Razorpay payments are only available in the Android or iOS app.'
                  : 'Payment failed: ${pay.message ?? 'cancelled'}')));
        }
        return;
      }
      paymentStatus = 'paid';
      paymentId = pay.paymentId;
    }
    final order = await FirebaseFirestore.instance.collection('orders').add({
      'userId': user.uid,
      'userEmail': user.email,
      'role': role,
      'items': [
        for (final i in cart.items.values)
          {
            'productId': i.product.id,
            'name': i.product.name,
            'qty': i.qty,
            'unitPrice': Pricing.unitPrice(i.product.price, role, i.qty),
          }
      ],
      'total': cart.total(role),
      'address': pickedAddress.address,
      'latitude': pickedAddress.latitude,
      'longitude': pickedAddress.longitude,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      if (paymentId != null) 'paymentId': paymentId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    cart.clear();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order placed! Waiting for admin approval.')));
    }
    try {
      await NotificationQueue.forUser(
        userId: user.uid,
        subject: 'AquaShop order received',
        body:
            'Your order #${order.id.substring(0, 6)} was received and is waiting for admin approval.',
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Order placed, but notification failed: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Cart.instance,
        builder: (_, __) {
          final cart = Cart.instance;
          if (cart.items.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.shopping_bag_outlined,
                    size: 72,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: .45)),
                const SizedBox(height: 14),
                Text('Your cart is empty',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Add products to start your order'),
              ]),
            );
          }
          return Column(children: [
            Expanded(
              child: ListView(children: [
                for (final i in cart.items.values)
                  ListTile(
                    title: Text(i.product.name, maxLines: 2),
                    subtitle: Text(
                        '₹${Pricing.unitPrice(i.product.price, role, i.qty).toStringAsFixed(0)} each • '
                        '₹${Pricing.lineTotal(i.product.price, role, i.qty).toStringAsFixed(0)}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            final q = i.qty - 1;
                            cart.setQty(
                                i.product.id,
                                (role == 'dealer' && q < Pricing.dealerMinQty)
                                    ? 0
                                    : q);
                          }),
                      Text('${i.qty}'),
                      IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: i.qty < i.product.stock
                              ? () => cart.setQty(i.product.id, i.qty + 1)
                              : null),
                    ]),
                  ),
              ]),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(
                      child: Text(
                          'Total ₹${cart.total(role).toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleLarge)),
                  FilledButton(
                      onPressed: () => _checkout(context),
                      child: const Text('Checkout')),
                ]),
              ),
            ),
          ]);
        },
      );
}
