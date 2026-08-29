import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/waitress_model.dart';

/// Persiste les données de staff sous forme JSON dans Hive.
class StaffLocalDataSource {
  final Box<String> box;
  static const key = 'staff';

  StaffLocalDataSource({required this.box});

  bool get hasData => readCache() != null;

  /// Retourne les données en cache ou null si le cache est absent/invalide.
  List<WaitressModel>? getWaitresses() => readCache();

  Future<void> saveWaitresses(List<WaitressModel> items) =>
      box.put(key, jsonEncode(items.map((item) => item.toJson()).toList()));

  Future<void> clear() => box.delete(key);

  List<WaitressModel>? readCache() {
    final raw = box.get(key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map(
            (item) => WaitressModel.fromJson(
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
