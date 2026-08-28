import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/orders_controller.dart';

/// Formate une date sans dépendre du package `intl` (non présent dans le
/// pubspec d'origine) afin de ne pas ajouter de nouvelle dépendance.
String _formatDateTime(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)} ${two(date.hour)}:${two(date.minute)}';
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersController>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrdersController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadOrders(),
          ),
        ],
      ),
      body: _buildBody(controller),
    );
  }

  Widget _buildBody(OrdersController controller) {
    if (controller.isLoading && controller.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null && controller.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(controller.errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => controller.loadOrders(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (controller.orders.isEmpty) {
      return const Center(child: Text('Aucune commande pour le moment.'));
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadOrders(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: controller.orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final order = controller.orders[index];
          return Card(
            child: ListTile(
              title: Text('Commande #${order.id}'),
              subtitle: Text(
                '${order.items.length} article(s) • '
                '${_formatDateTime(order.createdAt)}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${order.total.toStringAsFixed(0)} FCFA'),
                  Text(
                    order.status,
                    style: TextStyle(
                      color: order.status == 'pending'
                          ? Colors.orange
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
