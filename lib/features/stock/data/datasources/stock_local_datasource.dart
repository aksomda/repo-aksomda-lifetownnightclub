import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/stock_item_model.dart';

/// Cache local des stocks (JSON encodé dans une Box Hive), utilisé
/// comme repli quand l'API est injoignable (mode hors-ligne).
class StockLocalDataSource {
  final Box<String> box;
  static const key = 'stocks';

  StockLocalDataSource({required this.box});

  bool get hasData => box.get(key) != null;

  List<StockItemModel> getStocks() {
    final raw = box.get(key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .whereType<Map>()
        .map((e) => StockItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveStocks(List<StockItemModel> items) =>
      box.put(key, jsonEncode(items.map((e) => e.toJson()).toList()));

  Future<void> clear() => box.delete(key);
}
