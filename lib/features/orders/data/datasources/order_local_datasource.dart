import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/order_model.dart';

/// Cache local des commandes (JSON encodé dans une Box Hive), utilisé
/// comme repli quand l'API est injoignable (mode hors-ligne).
class OrderLocalDataSource {
  final Box<String> box;
  static const key = 'orders';

  OrderLocalDataSource({required this.box});

  bool get hasData => box.get(key) != null;

  List<OrderModel> getOrders() {
    final raw = box.get(key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .whereType<Map>()
        .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveOrders(List<OrderModel> items) =>
      box.put(key, jsonEncode(items.map((e) => e.toJson()).toList()));

  Future<void> clear() => box.delete(key);
}
