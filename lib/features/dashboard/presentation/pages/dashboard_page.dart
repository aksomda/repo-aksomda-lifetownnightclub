import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';

/// Affiche les indicateurs principaux et les raccourcis de navigation.
class DashboardPage extends StatefulWidget {
  final DashboardController controller;
  final VoidCallback onLogout;
  final void Function(int) onNavigate;

  const DashboardPage({
    super.key,
    required this.controller,
    required this.onLogout,
    required this.onNavigate,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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

  /// Construit une carte d'indicateur du tableau de bord.
  Widget buildCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.controller.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: widget.controller.loading
          ? const Center(child: CircularProgressIndicator())
          : widget.controller.error != null
          ? Center(child: Text(widget.controller.error!))
          : RefreshIndicator(
              onRefresh: widget.controller.load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'LIFETOWN — Gestion des boissons',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (data != null) ...[
                    buildCard(
                      'Produits',
                      '${data.products}',
                      Icons.local_bar,
                    ),
                    buildCard(
                      'Commandes',
                      '${data.orders}',
                      Icons.receipt_long,
                    ),
                    buildCard(
                      'Stocks faibles',
                      '${data.lowStocks}',
                      Icons.warning,
                    ),
                    buildCard('Serveuses', '${data.staff}', Icons.people),
                    buildCard(
                      'Chiffre d’affaires',
                      '${data.revenue.toStringAsFixed(0)} F',
                      Icons.payments,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => widget.onNavigate(1),
                        icon: const Icon(Icons.local_bar),
                        label: const Text('Menu'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => widget.onNavigate(2),
                        icon: const Icon(Icons.receipt),
                        label: const Text('Commandes'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => widget.onNavigate(3),
                        icon: const Icon(Icons.inventory),
                        label: const Text('Stocks'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => widget.onNavigate(4),
                        icon: const Icon(Icons.people),
                        label: const Text('Serveuses'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
