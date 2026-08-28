import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/staff_controller.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffController>().loadWaitresses();
    });
  }

  Future<void> _openAddDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle serveuse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Téléphone (optionnel)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              await context.read<StaffController>().addWaitress(
                    nameCtrl.text.trim(),
                    phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  );
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StaffController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Serveuses')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        child: const Icon(Icons.person_add),
      ),
      body: _buildBody(controller),
    );
  }

  Widget _buildBody(StaffController controller) {
    if (controller.isLoading && controller.waitresses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null && controller.waitresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(controller.errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => controller.loadWaitresses(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (controller.waitresses.isEmpty) {
      return const Center(child: Text('Aucune serveuse enregistrée.'));
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadWaitresses(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: controller.waitresses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final w = controller.waitresses[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(w.name.isNotEmpty ? w.name[0] : '?')),
              title: Text(w.name),
              subtitle: Text(w.phone ?? 'Pas de téléphone'),
              trailing: Icon(
                w.active ? Icons.check_circle : Icons.cancel,
                color: w.active ? Colors.green : Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }
}
