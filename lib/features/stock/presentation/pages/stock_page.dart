import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/stock_controller.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockController>().loadStocks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StockController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des Stocks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadStocks(),
          ),
        ],
      ),
      body: _buildBody(controller),
    );
  }

  Widget _buildBody(StockController controller) {
    if (controller.isLoading && controller.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null && controller.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(controller.errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => controller.loadStocks(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (controller.items.isEmpty) {
      return const Center(child: Text('Aucun produit en stock.'));
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadStocks(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: controller.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = controller.items[index];
          return Card(
            child: ListTile(
              leading: Icon(
                item.isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2,
                color: item.isLowStock ? Colors.red : Colors.green,
              ),
              title: Text(item.productName),
              subtitle: Text('Seuil minimum : ${item.minimumQuantity} ${item.unit}'),
              trailing: Text(
                '${item.quantity} ${item.unit}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: item.isLowStock ? Colors.red : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
