import 'package:flutter/foundation.dart';

import '../../data/repositories/menu_repository_impl.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/usecases/get_menu.dart';

class MenuController extends ChangeNotifier {
  final GetMenu getMenu;
  // Référence à l'implémentation concrète uniquement pour exposer le
  // flag "isFromCache" (mode hors-ligne) à l'écran, sans casser
  // l'abstraction du use case côté domain.
  final MenuRepositoryImpl repository;

  MenuController({required this.getMenu, required this.repository});

  List<MenuItemEntity> items = [];

  bool isLoading = false;
  bool isOffline = false;
  String? errorMessage;

  Future<void> loadMenu({bool forceRefresh = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      items = await getMenu(forceRefresh: forceRefresh);
      isOffline = repository.lastFetchWasFromCache;
    } catch (e) {
      errorMessage = 'Impossible de charger le menu.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<MenuItemEntity> byCategory(String category) {
    return items.where((item) => item.category == category).toList();
  }
}
