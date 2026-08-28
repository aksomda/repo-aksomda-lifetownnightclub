// Réécrit entièrement : la version d'origine avait de multiples erreurs de
// syntaxe (accolade `'price': 3500` en position d'argument nommé au lieu
// de `price:`), importait un mauvais nom de package
// (`package:lifetown_maquis/...` alors que le package s'appelle
// `repo_aksomda_lifetownnightclub`), référençait un fichier
// `.mocks.dart` jamais généré, et pointait vers
// `features/menu/data/repositories/menu_repository_impl.dart` qui
// n'existait pas encore à l'époque (l'impl vivait dans `domain/`).
//
// On utilise ici de vrais fakes écrits à la main (sous-classes qui
// surchargent les méthodes réseau) plutôt que mockito, pour ne dépendre
// d'aucune génération de code. Le cache local utilise une vraie Hive Box
// en mémoire (répertoire temporaire), ce qui est plus fiable qu'un mock
// de `Box`.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:repo_aksomda_lifetownnightclub/core/errors/app_exception.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/data/datasources/menu_local_datasource.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/data/datasources/menu_remote_datasource.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/data/models/menu_item_model.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/data/repositories/menu_repository_impl.dart';

class _FakeMenuRemoteDataSource extends MenuRemoteDataSource {
  _FakeMenuRemoteDataSource({this.itemsToReturn, this.shouldThrow = false})
      : super(dio: Dio());

  final List<MenuItemModel>? itemsToReturn;
  final bool shouldThrow;

  @override
  Future<List<MenuItemModel>> getMenu() async {
    if (shouldThrow) {
      throw const NetworkException();
    }
    return itemsToReturn ?? [];
  }
}

void main() {
  late Directory tempDir;
  late Box<MenuItemModel> box;

  setUpAll(() {
    Hive.registerAdapter(MenuItemModelAdapter());
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lifetown_hive_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<MenuItemModel>('menu_box_test');
  });

  tearDown(() async {
    await box.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('MenuRepositoryImpl', () {
    test(
      "récupère le menu depuis l'API et le met en cache quand forceRefresh=true",
      () async {
        final remote = _FakeMenuRemoteDataSource(itemsToReturn: [
          MenuItemModel(
            id: '1',
            name: 'Bière Sobbra',
            category: 'boisson',
            price: 700,
            available: true,
          ),
        ]);
        final local = MenuLocalDataSource(box: box);
        final repository = MenuRepositoryImpl(
          remoteDataSource: remote,
          localDataSource: local,
        );

        final result = await repository.getMenu(forceRefresh: true);

        expect(result, hasLength(1));
        expect(result.first.name, 'Bière Sobbra');
        expect(box.values.length, 1);
        expect(repository.lastFetchWasFromCache, isFalse);
      },
    );

    test(
      'retourne les données du cache si forceRefresh=false et le cache '
      'contient déjà des données (sans appeler le réseau)',
      () async {
        await box.put(
          '2',
          MenuItemModel(
            id: '2',
            name: 'Poulet Braisé',
            category: 'plat',
            price: 3500,
            available: true,
          ),
        );

        // shouldThrow=true : si le repository appelait le réseau par
        // erreur, ce test échouerait immédiatement.
        final remote = _FakeMenuRemoteDataSource(shouldThrow: true);
        final local = MenuLocalDataSource(box: box);
        final repository = MenuRepositoryImpl(
          remoteDataSource: remote,
          localDataSource: local,
        );

        final result = await repository.getMenu(forceRefresh: false);

        expect(result, hasLength(1));
        expect(result.first.name, 'Poulet Braisé');
        expect(repository.lastFetchWasFromCache, isTrue);
      },
    );

    test(
      'retourne les données du cache Hive si le réseau échoue '
      '(mode hors-ligne)',
      () async {
        await box.put(
          '3',
          MenuItemModel(
            id: '3',
            name: 'Alloco',
            category: 'accompagnement',
            price: 500,
            available: true,
          ),
        );

        final remote = _FakeMenuRemoteDataSource(shouldThrow: true);
        final local = MenuLocalDataSource(box: box);
        final repository = MenuRepositoryImpl(
          remoteDataSource: remote,
          localDataSource: local,
        );

        // forceRefresh=true force l'appel réseau, qui échoue, et on doit
        // retomber sur le cache existant.
        final result = await repository.getMenu(forceRefresh: true);

        expect(result, hasLength(1));
        expect(result.first.name, 'Alloco');
        expect(repository.lastFetchWasFromCache, isTrue);
      },
    );

    test(
      'lève une CacheException si le réseau échoue ET que le cache est vide',
      () async {
        final remote = _FakeMenuRemoteDataSource(shouldThrow: true);
        final local = MenuLocalDataSource(box: box);
        final repository = MenuRepositoryImpl(
          remoteDataSource: remote,
          localDataSource: local,
        );

        expect(
          () => repository.getMenu(forceRefresh: true),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });
}
