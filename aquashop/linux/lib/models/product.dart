import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id, name, category, imageUrl, description;
  final double price;
  final int stock;
  const Product({required this.id, required this.name, required this.category,
      required this.imageUrl, required this.description,
      required this.price, required this.stock});

  factory Product.fromDoc(DocumentSnapshot d) {
    final m = d.data() as Map<String, dynamic>;
    return Product(
      id: d.id, name: m['name'] ?? '', category: m['category'] ?? '',
      imageUrl: m['imageUrl'] ?? '', description: m['description'] ?? '',
      price: (m['price'] ?? 0).toDouble(), stock: (m['stock'] ?? 0) as int);
  }
}
