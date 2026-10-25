import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'pricing.dart';

class CartItem {
  final Product product;
  int qty;
  CartItem(this.product, this.qty);
}

/// App-wide cart (singleton). Screens listen with ListenableBuilder.
class Cart extends ChangeNotifier {
  Cart._();
  static final instance = Cart._();
  final Map<String, CartItem> items = {};

  int get count => items.values.fold(0, (s, i) => s + i.qty);

  void add(Product p, int qty) {
    final e = items[p.id];
    e == null ? items[p.id] = CartItem(p, qty) : e.qty += qty;
    notifyListeners();
  }

  void setQty(String id, int q) {
    q <= 0 ? items.remove(id) : items[id]!.qty = q;
    notifyListeners();
  }

  void clear() {
    items.clear();
    notifyListeners();
  }

  double total(String role) => items.values
      .fold(0.0, (s, i) => s + Pricing.lineTotal(i.product.price, role, i.qty));
}
