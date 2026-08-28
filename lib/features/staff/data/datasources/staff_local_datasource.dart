import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/waitress_model.dart';

/// Cache local du personnel (JSON encodé dans une Box Hive), utilisé
/// comme repli quand l'API est injoignable (mode hors-ligne).
class StaffLocalDataSource {
  final Box<String> box;
  static const key = 'staff';

  StaffLocalDataSource({required this.box});

  bool get hasData => box.get(key) != null;

  List<WaitressModel> getWaitresses() {
    final raw = box.get(key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .whereType<Map>()
        .map((e) => WaitressModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveWaitresses(List<WaitressModel> items) =>
      box.put(key, jsonEncode(items.map((e) => e.toJson()).toList()));

  Future<void> clear() => box.delete(key);
}
