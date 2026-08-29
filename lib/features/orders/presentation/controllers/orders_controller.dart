import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/get_orders.dart';

/// Gère l'état de chargement de la fonctionnalité Orders.
class OrdersController extends ChangeNotifier {
  final GetOrders get;

  OrdersController(this.get);

  List<OrderEntity> items = [];
  bool loading = false;
  String? error;

  /// Charge les données depuis le repository.
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      items = await get();
    } catch (exception) {
      error = messageFrom(exception);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  String messageFrom(Object exception) {
    if (exception is AppException) return exception.message;
    return 'Une erreur inattendue est survenue. Veuillez réessayer.';
  }
}
