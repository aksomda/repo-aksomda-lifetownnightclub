import 'package:flutter/material.dart';
import '../controllers/stock_controller.dart';

class StockPage extends StatefulWidget {
  final StockController controller;
  const StockPage({super.key, required this.controller});
  @override State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  @override void initState() { super.initState(); widget.controller.addListener(onControllerChanged); widget.controller.load(); }
  void onControllerChanged() { if (mounted) setState(() {}); }
  @override void dispose() { widget.controller.removeListener(onControllerChanged); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stocks'), actions: [
        IconButton(onPressed: widget.controller.load, icon: const Icon(Icons.refresh)),
      ]),
      body: widget.controller.loading
          ? const Center(child: CircularProgressIndicator())
          : widget.controller.error != null
              ? Center(child: Text(widget.controller.error!))
              : ListView.builder(
                  itemCount: widget.controller.items.length,
                  itemBuilder: (context, index) {
                    final stock = widget.controller.items[index];
                    return ListTile(
                      title: Text(stock.productName),
                      subtitle: Text('${stock.quantity} ${stock.unit} • seuil ${stock.minimumQuantity}'),
                      trailing: stock.isLowStock
                          ? const Chip(label: Text('Stock faible'))
                          : const Icon(Icons.check),
                    );
                  },
                ),
    );
  }
}
