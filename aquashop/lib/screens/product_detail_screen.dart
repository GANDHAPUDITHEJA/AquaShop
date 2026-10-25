import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/cart.dart';
import '../services/pricing.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product p;
  final String role;
  const ProductDetailScreen(this.p, this.role, {super.key});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late int qty = widget.role == 'dealer' ? Pricing.dealerMinQty : 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.p, role = widget.role;
    final unit = Pricing.unitPrice(p.price, role, qty);
    final off = (Pricing.discount(role, qty) * 100).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: ListView(children: [
        AspectRatio(
          aspectRatio: 1.15,
          child: CachedNetworkImage(
              imageUrl: p.imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  const Center(child: Icon(Icons.water_drop, size: 64))),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Chip(
                avatar: const Icon(Icons.category_outlined, size: 16),
                label: Text(p.category)),
            const SizedBox(height: 12),
            Text('₹${unit.toStringAsFixed(0)} each',
                style: Theme.of(context).textTheme.headlineMedium),
            if (off > 0)
              Text(
                  '$off% bulk discount applied (list ₹${p.price.toStringAsFixed(0)})',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary)),
            if (role == 'dealer')
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Dealer tiers: 5+ → 10% • 10+ → 15% • 25+ → 20%'),
              ),
            const SizedBox(height: 12),
            Text(p.description),
            const SizedBox(height: 8),
            Row(children: [
              Icon(p.stock > 0 ? Icons.check_circle : Icons.cancel,
                  size: 18, color: p.stock > 0 ? Colors.green : Colors.red),
              const SizedBox(width: 6),
              Text(p.stock > 0 ? 'In stock: ${p.stock}' : 'Out of stock',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            IconButton.outlined(
                icon: const Icon(Icons.remove),
                onPressed: qty > (role == 'dealer' ? Pricing.dealerMinQty : 1)
                    ? () => setState(() => qty--)
                    : null),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('$qty',
                    style: Theme.of(context).textTheme.titleLarge)),
            IconButton.outlined(
                icon: const Icon(Icons.add),
                onPressed: qty < p.stock ? () => setState(() => qty++) : null),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: p.stock == 0
                    ? null
                    : () {
                        Cart.instance.add(p, qty);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Added $qty × ${p.name} to cart')));
                        Navigator.pop(context);
                      },
                child: const Text('Add to cart'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
