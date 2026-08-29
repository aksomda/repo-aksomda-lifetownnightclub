import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/order_model.dart';

/// Persiste les données de orders sous forme JSON dans Hive.
class OrderLocalDataSource {
  final Box<String> box;
  static const key = 'orders';

  OrderLocalDataSource({required this.box});

  bool get hasData => readCache() != null;

  /// Retourne les données en cache ou null si le cache est absent/invalide.
  List<OrderModel>? getOrders() => readCache();

  Future<void> saveOrders(List<OrderModel> items) =>
      box.put(key, jsonEncode(items.map((item) => item.toJson()).toList()));

  Future<void> clear() => box.delete(key);

  List<OrderModel>? readCache() {
    final raw = box.get(key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map(
            (item) => OrderModel.fromJson(
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
