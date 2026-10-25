/// Dealer bulk rules: minimum 5 units per line, tiered discount.
/// Customers always pay list price.
class Pricing {
  static const dealerMinQty = 5;

  static double discount(String role, int qty) {
    if (role != 'dealer') return 0;
    if (qty >= 25) return 0.20;
    if (qty >= 10) return 0.15;
    if (qty >= dealerMinQty) return 0.10;
    return 0;
  }

  static double unitPrice(double base, String role, int qty) =>
      base * (1 - discount(role, qty));

  static double lineTotal(double base, String role, int qty) =>
      unitPrice(base, role, qty) * qty;

  /// Returns an error message, or null when the quantity is allowed.
  static String? validateQty(String role, int qty) =>
      (role == 'dealer' && qty < dealerMinQty)
          ? 'Dealers must order at least $dealerMinQty units per item' : null;
}
