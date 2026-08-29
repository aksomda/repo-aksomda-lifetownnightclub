import 'package:flutter/material.dart';

import '../controllers/orders_controller.dart';

/// Affiche la liste des commandes et son état de chargement.
class OrdersPage extends StatefulWidget {
  final OrdersController controller;

  const OrdersPage({super.key, required this.controller});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(onControllerChanged);
    widget.controller.load();
  }

  void onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes'),
        actions: [
          IconButton(
            onPressed: widget.controller.load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: widget.controller.loading
          ? const Center(child: CircularProgressIndicator())
          : widget.controller.error != null
          ? Center(child: Text(widget.controller.error!))
          : ListView.builder(
              itemCount: widget.controller.items.length,
              itemBuilder: (context, index) {
                final order = widget.controller.items[index];
                return ListTile(
                  title: Text('Commande #${order.id}'),
                  subtitle: Text(
                    '${order.status} • ${order.items.length} article(s)',
                  ),
                  trailing: Text('${order.total.toStringAsFixed(0)} F'),
                );
              },
            ),
    );
  }
}
