import 'package:hive/hive.dart';

import '../models/menu_item_model.dart';

/// Bug corrigé : ce fichier vivait par erreur dans
/// `features/auth/data/datasources/menu_local_datasource.dart` (mauvaise
/// feature). Déplacé ici, dans `features/menu/`, là où il appartient.
class MenuLocalDataSource {
  final Box<MenuItemModel> box;

  MenuLocalDataSource({required this.box});

  List<MenuItemModel> getMenu() {
    return box.values.toList();
  }

  bool get hasData => box.isNotEmpty;

  Future<void> saveMenu(List<MenuItemModel> items) async {
    await box.clear();

    for (final item in items) {
      await box.put(item.id, item);
    }
  }

  Future<void> clear() async {
    await box.clear();
  }
}
