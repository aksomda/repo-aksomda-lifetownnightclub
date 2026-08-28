// Bug corrigé : cette implémentation (qui appelle Dio et Hive) vivait par
// erreur dans `domain/repositories/menu_repository_impl.dart`. La couche
// domain ne doit contenir que le contrat abstrait `MenuRepository` ;
// l'implémentation concrète a été déplacée ici, dans la couche data.
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/menu_local_datasource.dart';
import '../datasources/menu_remote_datasource.dart';

class MenuRepositoryImpl implements MenuRepository {
  final MenuRemoteDataSource remoteDataSource;
  final MenuLocalDataSource localDataSource;

  MenuRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  bool _lastFetchWasFromCache = false;
  bool get lastFetchWasFromCache => _lastFetchWasFromCache;

  @override
  Future<List<MenuItemEntity>> getMenu({bool forceRefresh = false}) async {
    if (!forceRefresh && localDataSource.hasData) {
      _lastFetchWasFromCache = true;
      return localDataSource.getMenu().map((item) => item.toEntity()).toList();
    }

    try {
      final remoteItems = await remoteDataSource.getMenu();

      await localDataSource.saveMenu(remoteItems);
      _lastFetchWasFromCache = false;

      return remoteItems.map((item) => item.toEntity()).toList();
    } catch (_) {
      // Mode hors-ligne : on retombe sur le cache Hive si disponible.
      if (localDataSource.hasData) {
        _lastFetchWasFromCache = true;
        return localDataSource
            .getMenu()
            .map((item) => item.toEntity())
            .toList();
      }

      throw const CacheException(
        'Aucun menu disponible : ni le serveur ni le cache local ne '
        'répondent.',
      );
    }
  }
}
