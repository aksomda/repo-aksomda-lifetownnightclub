// Bug corrigé : le dashboard n'affichait que des cartes statiques à "0",
// jamais reliées à aucune donnée. Il consomme maintenant les controllers
// Orders/Stock déjà chargés ailleurs dans l'app (aucun nouvel appel
// réseau ici, juste de la lecture d'état partagé via Provider).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../../stock/presentation/controllers/stock_controller.dart';
import '../../../staff/presentation/controllers/staff_controller.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersController>().loadOrders();
      context.read<StockController>().loadStocks();
      context.read<StaffController>().loadWaitresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersController>();
    final stock = context.watch<StockController>();
    final staff = context.watch<StaffController>();

    return Scaffold(
      appBar: AppBar(title: const Text('LIFETOWN')),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            orders.loadOrders(),
            stock.loadStocks(),
            staff.loadWaitresses(),
          ]);
        },
        child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _DashboardCard(
              icon: Icons.receipt_long,
              title: 'Commandes en cours',
              value: '${orders.pendingCount}',
            ),
            _DashboardCard(
              icon: Icons.receipt,
              title: 'Total commandes',
              value: '${orders.orders.length}',
            ),
            _DashboardCard(
              icon: Icons.inventory,
              title: 'Stocks faibles',
              value: '${stock.lowStockItems.length}',
            ),
            _DashboardCard(
              icon: Icons.people,
              title: 'Serveuses actives',
              value: '${staff.waitresses.where((w) => w.active).length}',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
