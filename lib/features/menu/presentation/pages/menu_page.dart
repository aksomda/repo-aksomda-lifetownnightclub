// Bug corrigé : ce fichier était une copie de `menu_controller.dart`
// (aucun widget, aucun `build()`) — l'écran "Menu" n'existait tout
// simplement pas. Remplacé par un vrai écran connecté au controller.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/menu_controller.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuController>().loadMenu();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MenuController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu — Boissons & Plats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadMenu(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          if (controller.isOffline)
            Container(
              width: double.infinity,
              color: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: const Text(
                'Mode hors-ligne — données en cache',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          Expanded(child: _buildBody(controller)),
        ],
      ),
    );
  }

  Widget _buildBody(MenuController controller) {
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
              onPressed: () => controller.loadMenu(forceRefresh: true),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (controller.items.isEmpty) {
      return const Center(child: Text('Aucun article dans le menu.'));
    }

    final categories = controller.items.map((e) => e.category).toSet().toList();

    return RefreshIndicator(
      onRefresh: () => controller.loadMenu(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final category in categories) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                category.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            ...controller.byCategory(category).map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.name),
                      trailing: Text('${item.price.toStringAsFixed(0)} FCFA'),
                      subtitle: item.available
                          ? null
                          : const Text(
                              'Indisponible',
                              style: TextStyle(color: Colors.red),
                            ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
