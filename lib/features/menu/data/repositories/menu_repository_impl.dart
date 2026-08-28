import '../../../../core/network/dio_client.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/menu_local_datasource.dart';
import '../datasources/menu_remote_datasource.dart';

class MenuRepositoryImpl implements MenuRepository {
  final MenuRemoteDataSource remote;
  final MenuLocalDataSource local;
  MenuRepositoryImpl({required this.remote, required this.local});

  @override
  Future<List<MenuItemEntity>> getMenu({bool forceRefresh = false}) async {
    try {
      final r = await remote.getMenu();
      await local.saveMenu(r);
      return r;
    } catch (e) {
      // Hors-ligne (ou API en erreur) : on retombe sur le dernier menu mis
      // en cache s'il existe, sinon on remonte une erreur utilisateur claire.
      if (local.hasData) return local.getMenu();
      throw mapDioException(e);
    }
  }
}
