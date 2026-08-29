import '../../../../core/network/dio_client.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/menu_local_datasource.dart';
import '../datasources/menu_remote_datasource.dart';

/// Implémente le contrat du menu avec stratégie réseau puis cache.
class MenuRepositoryImpl implements MenuRepository {
  final MenuRemoteDataSource remote;
  final MenuLocalDataSource local;

  MenuRepositoryImpl({required this.remote, required this.local});

  @override
  Future<List<MenuItemEntity>> getMenu({bool forceRefresh = false}) async {
    try {
      final result = await remote.getMenu();
      try {
        await local.saveMenu(result);
      } catch (_) {
        // Une panne de persistance locale ne doit pas masquer une réponse API valide.
      }
      return result;
    } catch (error) {
      final cached = local.getMenu();
      if (cached != null) return cached;
      throw mapDioException(error);
    }
  }
}
