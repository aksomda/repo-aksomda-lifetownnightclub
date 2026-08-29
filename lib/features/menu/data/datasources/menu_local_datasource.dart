import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/menu_item_model.dart';

/// Persiste le menu sous forme JSON dans Hive.
class MenuLocalDataSource {
  final Box<String> box;
  static const key = 'menu';

  MenuLocalDataSource({required this.box});

  bool get hasData => readCache() != null;

  /// Retourne le menu en cache ou null si le cache est absent/invalide.
  List<MenuItemModel>? getMenu() => readCache();

  Future<void> saveMenu(List<MenuItemModel> items) =>
      box.put(key, jsonEncode(items.map((item) => item.toJson()).toList()));

  Future<void> clear() => box.delete(key);

  List<MenuItemModel>? readCache() {
    final raw = box.get(key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map(
            (item) => MenuItemModel.fromJson(
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
