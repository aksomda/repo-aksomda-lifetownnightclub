import '../../../../core/network/dio_client.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/usecases/get_menu.dart';

class MenuController extends ChangeNotifier {
  final GetMenu getMenu;
  MenuController({required this.getMenu});
  List<MenuItemEntity> items = [];
  bool loading = false, offline = false;
  String? error;
  Future<void> load({bool refresh = false}) async {
    loading = true;
    error = null;
    offline = false;
    notifyListeners();
    try {
      items = await getMenu(forceRefresh: refresh);
    } catch (e) {
      error = mapDioException(e).message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
