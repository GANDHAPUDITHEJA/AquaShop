import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/pricing.dart';
import '../services/seed_data.dart';
import 'product_detail_screen.dart';

class ShopScreen extends StatefulWidget {
  final String role;
  const ShopScreen({super.key, required this.role});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _q = '', _cat = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 2),
        child: Text(
            widget.role == 'dealer'
                ? 'Bulk essentials for your business'
                : 'Find your perfect water solution',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
        child: Text(
            widget.role == 'dealer'
                ? 'Better rates on larger quantities'
                : 'Trusted purifiers, filters and accessories',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.blueGrey)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
        child: SearchBar(
          hintText: 'Search purifiers, filters, pumps…',
          leading: const Icon(Icons.search),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          onChanged: (v) => setState(() => _q = v.toLowerCase()),
        ),
      ),
      SizedBox(
        height: 48,
        child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final c in ['All', ...categories])
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: ChoiceChip(
                      label: Text(c),
                      selected: _cat == c,
                      onSelected: (_) => setState(() => _cat = c)),
                ),
            ]),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .orderBy('name')
              .snapshots(),
          builder: (_, snap) {
            if (snap.hasError) return Center(child: Text('${snap.error}'));
            if (!snap.hasData)
              return const Center(child: CircularProgressIndicator());
            final items = snap.data!.docs
                .map(Product.fromDoc)
                .where((p) =>
                    (_cat == 'All' || p.category == _cat) &&
                    p.name.toLowerCase().contains(_q))
                .toList();
            if (items.isEmpty)
              return const Center(child: Text('No products found'));
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width > 650 ? 3 : 2,
                  childAspectRatio: 0.67,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12),
              itemCount: items.length,
              itemBuilder: (_, i) => _ProductCard(items[i], widget.role),
            );
          },
        ),
      ),
    ]);
  }
}

class _ProductCard extends StatelessWidget {
  final Product p;
  final String role;
  const _ProductCard(this.p, this.role);

  @override
  Widget build(BuildContext context) {
    final dealer = role == 'dealer';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(p, role))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: p.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (_, __, ___) =>
                      const Center(child: Icon(Icons.water_drop, size: 40)),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Text(p.category,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('₹${p.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium),
              if (dealer)
                Text(
                    '₹${Pricing.unitPrice(p.price, role, Pricing.dealerMinQty).toStringAsFixed(0)} at ${Pricing.dealerMinQty}+ units',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary)),
            ]),
          ),
        ]),
      ),
    );
  }
}
