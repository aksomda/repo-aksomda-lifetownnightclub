import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/usecases/get_menu.dart';

/// Gère le chargement et l'état d'affichage du menu.
class MenuController extends ChangeNotifier {
  final GetMenu getMenu;

  MenuController({required this.getMenu});

  List<MenuItemEntity> items = [];
  bool loading = false;
  bool offline = false;
  String? error;

  /// Charge le menu et autorise un rafraîchissement explicite depuis l'API.
  Future<void> load({bool refresh = false}) async {
    loading = true;
    error = null;
    offline = false;
    notifyListeners();

    try {
      items = await getMenu(forceRefresh: refresh);
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
