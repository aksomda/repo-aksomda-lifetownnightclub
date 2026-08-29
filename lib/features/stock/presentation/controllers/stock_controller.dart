import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/usecases/get_stocks.dart';

/// Gère l'état de chargement de la fonctionnalité Stock.
class StockController extends ChangeNotifier {
  final GetStocks get;

  StockController(this.get);

  List<StockItemEntity> items = [];
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
