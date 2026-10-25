import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Role shells. Each tab is a placeholder to be built in the next steps.
class _Shell extends StatefulWidget {
  final String title;
  final List<(String, IconData)> tabs;
  const _Shell(this.title, this.tabs, {super.key});
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _i = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title), actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: AuthService().signOut)
        ]),
        body: Center(child: Text(widget.tabs[_i].$1)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (i) => setState(() => _i = i),
          destinations: [for (final t in widget.tabs)
            NavigationDestination(icon: Icon(t.$2), label: t.$1)],
        ),
      );
}

class CustomerHome extends _Shell {
  const CustomerHome({super.key}) : super('AquaShop', const [
    ('Shop', Icons.storefront), ('Cart', Icons.shopping_cart),
    ('Orders', Icons.receipt_long), ('Service', Icons.build)]);
}

class DealerHome extends _Shell {
  const DealerHome({super.key}) : super('AquaShop Dealer', const [
    ('Bulk Shop', Icons.inventory_2), ('Cart', Icons.shopping_cart),
    ('Orders', Icons.receipt_long), ('Service', Icons.build)]);
}

class AdminHome extends _Shell {
  const AdminHome({super.key}) : super('Admin', const [
    ('Orders', Icons.pending_actions), ('Products', Icons.inventory),
    ('Service Desk', Icons.support_agent)]);
}
