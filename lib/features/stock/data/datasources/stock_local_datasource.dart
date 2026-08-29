import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/stock_item_model.dart';

/// Persiste les données de stocks sous forme JSON dans Hive.
class StockLocalDataSource {
  final Box<String> box;
  static const key = 'stocks';

  StockLocalDataSource({required this.box});

  bool get hasData => readCache() != null;

  /// Retourne les données en cache ou null si le cache est absent/invalide.
  List<StockItemModel>? getStocks() => readCache();

  Future<void> saveStocks(List<StockItemModel> items) =>
      box.put(key, jsonEncode(items.map((item) => item.toJson()).toList()));

  Future<void> clear() => box.delete(key);

  List<StockItemModel>? readCache() {
    final raw = box.get(key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map(
            (item) => StockItemModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
