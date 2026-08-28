import 'package:flutter/foundation.dart';

import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

class OrdersController extends ChangeNotifier {
  final OrderRepository repository;

  OrdersController({required this.repository});

  List<OrderEntity> orders = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadOrders() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      orders = await repository.getOrders();
    } catch (_) {
      errorMessage = 'Impossible de charger les commandes.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrder({
    String? tableId,
    String? waitressId,
    required List<OrderItem> items,
  }) async {
    try {
      final created = await repository.createOrder(
        tableId: tableId,
        waitressId: waitressId,
        items: items,
      );
      orders = [created, ...orders];
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'Impossible de créer la commande.';
      notifyListeners();
      return false;
    }
  }

  Future<void> updateStatus(String orderId, String status) async {
    try {
      final updated = await repository.updateOrderStatus(
        orderId: orderId,
        status: status,
      );
      orders = [
        for (final o in orders) o.id == orderId ? updated : o,
      ];
      notifyListeners();
    } catch (_) {
      errorMessage = 'Impossible de mettre à jour le statut.';
      notifyListeners();
    }
  }

  int get pendingCount => orders.where((o) => o.status == 'pending').length;
}
