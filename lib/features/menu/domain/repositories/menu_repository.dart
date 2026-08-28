import '../entities/menu_item.dart'; abstract class MenuRepository { Future<List<MenuItemEntity>> getMenu({bool forceRefresh=false}); }
