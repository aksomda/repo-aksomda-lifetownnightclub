import 'package:flutter/material.dart';

import '../controllers/staff_controller.dart';

/// Affiche la liste du personnel et son état d'activité.
class StaffPage extends StatefulWidget {
  final StaffController controller;

  const StaffPage({super.key, required this.controller});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
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
        title: const Text('Serveuses'),
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
                final staff = widget.controller.items[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      staff.name.isEmpty ? '?' : staff.name[0].toUpperCase(),
                    ),
                  ),
                  title: Text(staff.name),
                  subtitle: Text(staff.phone ?? 'Téléphone non renseigné'),
                  trailing: Icon(
                    staff.active ? Icons.check_circle : Icons.block,
                  ),
                );
              },
            ),
    );
  }
}
