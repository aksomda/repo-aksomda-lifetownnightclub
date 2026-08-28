import '../entities/menu_item.dart';
import '../repositories/menu_repository.dart';

class GetMenu {
  final MenuRepository repository;

  GetMenu(this.repository);

  Future<List<MenuItemEntity>> call({bool forceRefresh = false}) {
    return repository.getMenu(forceRefresh: forceRefresh);
  }
}
