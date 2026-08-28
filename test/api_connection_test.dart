// Ajouté : n'existait pas dans le projet d'origine.
//
// Ce test exerce la véritable chaîne Flutter <-> API sans lancer de
// vrai serveur : on remplace uniquement le transport bas niveau de Dio
// (`HttpClientAdapter`) par un faux adaptateur qui simule les réponses
// HTTP. Tout le reste est réel : `AuthInterceptor`, `SecureTokenStorage`
// (avec le canal de la plateforme mocké), `AuthRemoteDataSource`,
// `AuthRepositoryImpl`, et le parsing JSON réel de `AuthResponseModel`.
//
// Cela permet de vérifier, sans backend, que :
// 1) le login envoie bien le bon payload et parse la vraie réponse JSON,
// 2) les tokens sont bien persistés après le login,
// 3) l'intercepteur injecte bien `Authorization: Bearer <token>` sur les
//    requêtes suivantes (ici vers /menu).
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_aksomda_lifetownnightclub/core/constants/api_constants.dart';
import 'package:repo_aksomda_lifetownnightclub/core/database/secure_token_storage.dart';
import 'package:repo_aksomda_lifetownnightclub/core/network/auth_interceptor.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/data/repositories/auth_repository_impl.dart';

/// Simule le canal de plateforme utilisé par `flutter_secure_storage`
/// (indisponible dans l'environnement de test `flutter_test`, qui ne
/// lance aucun vrai appareil/simulateur) avec un simple stockage en
/// mémoire.
void _installFakeSecureStorageChannel() {
  final store = <String, String>{};
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  channel.setMockMethodCallHandler((call) async {
    final args = (call.arguments as Map?) ?? {};
    switch (call.method) {
      case 'write':
        store[args['key'] as String] = args['value'] as String;
        return null;
      case 'read':
        return store[args['key'] as String];
      case 'containsKey':
        return store.containsKey(args['key'] as String);
      case 'delete':
        store.remove(args['key']);
        return null;
      case 'deleteAll':
        store.clear();
        return null;
      case 'readAll':
        return store;
      default:
        return null;
    }
  });
}

/// Faux adaptateur Dio : joue le rôle du serveur HTTP pour /auth/login et
/// /menu, sans ouvrir la moindre socket réseau.
class _FakeApiAdapter implements HttpClientAdapter {
  String? capturedAuthHeader;
  int menuCallCount = 0;
  Map<String, dynamic>? capturedLoginBody;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == ApiConstants.login && options.method == 'POST') {
      capturedLoginBody = options.data as Map<String, dynamic>;

      final body = jsonEncode({
        'user': {
          'id': '1',
          'name': 'Traoré',
          'prename': 'Awa',
          'age': 24,
          'telephone': '70000000',
          'email': capturedLoginBody!['email'],
          'role': 'admin',
        },
        'access_token': 'fake-access-token',
        'refresh_token': 'fake-refresh-token',
      });

      return ResponseBody.fromString(
        body,
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.path == ApiConstants.menu && options.method == 'GET') {
      menuCallCount++;
      capturedAuthHeader = options.headers['Authorization'] as String?;

      if (capturedAuthHeader == 'Bearer fake-access-token') {
        return ResponseBody.fromString(
          jsonEncode([
            {
              'id': '1',
              'name': 'Sobbra',
              'category': 'boisson',
              'price': 700,
              'available': true,
            },
          ]),
          200,
        );
      }
      return ResponseBody.fromString(
        jsonEncode({'message': 'Unauthorized'}),
        401,
      );
    }

    return ResponseBody.fromString(jsonEncode({'message': 'Not found'}), 404);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _installFakeSecureStorageChannel();

  test(
    'connexion Flutter <-> API : login réel puis requête authentifiée '
    'avec injection automatique du token',
    () async {
      final tokenStorage = SecureTokenStorage();
      final adapter = _FakeApiAdapter();

      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
        ..httpClientAdapter = adapter
        ..interceptors.add(AuthInterceptor(tokenStorage: tokenStorage));

      final remoteDataSource = AuthRemoteDataSource(dio: dio);
      final authRepository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        tokenStorage: tokenStorage,
      );

      // 1) Le login exerce toute la chaîne : sérialisation de la requête,
      // vrai parsing JSON de la réponse, persistance des tokens.
      final user = await authRepository.login(
        email: 'awa@lifetown.com',
        password: 'password',
      );

      expect(user.name, 'Traoré');
      expect(user.email, 'awa@lifetown.com');
      expect(adapter.capturedLoginBody?['email'], 'awa@lifetown.com');
      expect(await tokenStorage.getAccessToken(), 'fake-access-token');
      expect(await tokenStorage.getRefreshToken(), 'fake-refresh-token');

      // 2) Une requête ultérieure vers /menu doit automatiquement porter
      // le token stocké après le login, sans action manuelle.
      final menuResponse = await dio.get(ApiConstants.menu);

      expect(menuResponse.statusCode, 200);
      expect(adapter.capturedAuthHeader, 'Bearer fake-access-token');
      expect(adapter.menuCallCount, 1);
      expect((menuResponse.data as List).first['name'], 'Sobbra');
    },
  );
}
