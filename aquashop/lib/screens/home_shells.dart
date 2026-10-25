import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_products_screen.dart';
import 'shop_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'service_screen.dart';
import '../services/cart.dart';
import '../services/notification_service.dart';

class _Shell extends StatefulWidget {
  final String title;
  final List<(String, IconData)> tabs;
  final List<Widget> pages;
  const _Shell(this.title, this.tabs, this.pages, {super.key});
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    NotificationService.init((title, body) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$title — $body')));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          titleSpacing: 20,
          title: Text(widget.title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          actions: [
            if (widget.title != 'Admin')
              ListenableBuilder(
                listenable: Cart.instance,
                builder: (_, __) => IconButton(
                  tooltip: 'Cart',
                  onPressed: () => setState(() => _i = 1),
                  icon: Badge(
                    isLabelVisible: Cart.instance.count > 0,
                    label: Text('${Cart.instance.count}'),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () {
                Cart.instance.clear();
                NotificationService.reset();
                AuthService().signOut();
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: widget.pages[_i],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (i) => setState(() => _i = i),
          destinations: [
            for (final t in widget.tabs)
              NavigationDestination(icon: Icon(t.$2), label: t.$1)
          ],
        ),
      );
}

class CustomerHome extends _Shell {
  const CustomerHome({super.key})
      : super('AquaShop', const [
          ('Shop', Icons.storefront),
          ('Cart', Icons.shopping_cart),
          ('Orders', Icons.receipt_long),
          ('Service', Icons.build)
        ], const [
          const ShopScreen(role: 'customer'),
          const CartScreen(role: 'customer'),
          const OrdersScreen(),
          const ServiceScreen()
        ]);
}

class DealerHome extends _Shell {
  const DealerHome({super.key})
      : super('AquaShop Dealer', const [
          ('Bulk Shop', Icons.inventory_2),
          ('Cart', Icons.shopping_cart),
          ('Orders', Icons.receipt_long),
          ('Service', Icons.build)
        ], const [
          const ShopScreen(role: 'dealer'),
          const CartScreen(role: 'dealer'),
          const OrdersScreen(),
          const ServiceScreen()
        ]);
}

class AdminHome extends _Shell {
  const AdminHome({super.key})
      : super('Admin', const [
          ('Orders', Icons.pending_actions),
          ('Products', Icons.inventory),
          ('Service Desk', Icons.support_agent)
        ], const [
          const OrdersScreen(admin: true),
          const AdminProductsScreen(),
          const ServiceScreen(admin: true)
        ]);
}
