import 'package:flutter/material.dart';
import '../controllers/menu_controller.dart' as menu_feature;

class MenuPage extends StatefulWidget {
  final menu_feature.MenuController controller;
  const MenuPage({super.key, required this.controller});
  @override State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override void initState() { super.initState(); widget.controller.addListener(onControllerChanged); widget.controller.load(); }
  void onControllerChanged() { if (mounted) setState(() {}); }
  @override void dispose() { widget.controller.removeListener(onControllerChanged); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<dynamic>>{};
    for (final item in widget.controller.items) {
      groups.putIfAbsent(item.category, () => <dynamic>[]).add(item);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Menu'), actions: [
        IconButton(onPressed: () => widget.controller.load(refresh: true), icon: const Icon(Icons.refresh)),
      ]),
      body: widget.controller.loading
          ? const Center(child: CircularProgressIndicator())
          : widget.controller.error != null && widget.controller.items.isEmpty
              ? Center(child: Text(widget.controller.error!))
              : ListView(
                  children: groups.entries.expand((entry) => <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                      child: Text(entry.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...entry.value.map((item) => ListTile(
                      title: Text(item.name),
                      subtitle: Text(item.available ? 'Disponible' : 'Indisponible'),
                      trailing: Text('${item.price.toStringAsFixed(0)} F'),
                    )),
                  ]).toList(),
                ),
    );
  }
}
