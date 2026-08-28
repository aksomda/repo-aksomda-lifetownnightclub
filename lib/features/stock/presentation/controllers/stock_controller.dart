import 'package:flutter/foundation.dart';

import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/stock_repository.dart';

class StockController extends ChangeNotifier {
  final StockRepository repository;

  StockController({required this.repository});

  List<StockItemEntity> items = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadStocks() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      items = await repository.getStocks();
    } catch (_) {
      errorMessage = 'Impossible de charger les stocks.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String productId, double quantity) async {
    try {
      final updated = await repository.updateQuantity(
        productId: productId,
        quantity: quantity,
      );
      items = [
        for (final i in items) i.productId == productId ? updated : i,
      ];
      notifyListeners();
    } catch (_) {
      errorMessage = 'Impossible de mettre à jour le stock.';
      notifyListeners();
    }
  }

  List<StockItemEntity> get lowStockItems =>
      items.where((i) => i.isLowStock).toList();
}
