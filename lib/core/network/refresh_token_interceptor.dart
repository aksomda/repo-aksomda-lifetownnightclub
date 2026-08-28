import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../database/secure_token_storage.dart';

/// Intercepteur qui gère le rafraîchissement automatique du token JWT.
///
/// Ce fichier était vide dans le projet d'origine (une des causes pour
/// lesquelles l'app ne compilait/ne fonctionnait pas correctement en
/// conditions réelles : toute expiration de token cassait la session
/// sans possibilité de la restaurer).
///
/// Fonctionnement :
/// 1. Laisse passer toutes les requêtes/réponses normalement.
/// 2. Si une réponse échoue avec un code 401 (token expiré) et que ce
///    n'est pas déjà un appel à `/auth/refresh`, on tente un refresh :
///    - un seul refresh à la fois (évite les appels concurrents),
///    - les requêtes qui arrivent pendant le refresh attendent le
///      résultat au lieu de déclencher un nouveau refresh,
/// 3. Si le refresh réussit, la requête initiale est rejouée avec le
///    nouveau token.
/// 4. Si le refresh échoue (refresh token expiré/absent), l'erreur 401
///    d'origine est propagée pour que l'application déconnecte
///    l'utilisateur (voir `AuthController.logout`).
class RefreshTokenInterceptor extends Interceptor {
  final SecureTokenStorage tokenStorage;

  /// Instance Dio dédiée à l'appel de refresh, sans intercepteur, afin
  /// d'éviter une boucle infinie (le refresh échouant en 401
  /// redéclencherait un refresh, etc.).
  final Dio _refreshDio;

  bool _isRefreshing = false;
  final List<void Function(String newToken)> _waiters = [];

  RefreshTokenInterceptor({
    required this.tokenStorage,
    String baseUrl = ApiConstants.baseUrl,
  }) : _refreshDio = Dio(BaseOptions(baseUrl: baseUrl));

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path == ApiConstants.refreshToken;

    if (!isUnauthorized || isRefreshCall) {
      handler.next(err);
      return;
    }

    try {
      final newToken = await _refreshAccessToken();

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newToken';

      final retryDio = Dio(BaseOptions(baseUrl: retryOptions.baseUrl));
      final response = await retryDio.fetch(retryOptions);
      handler.resolve(response);
    } catch (_) {
      await tokenStorage.clear();
      handler.next(err);
    }
  }

  Future<String> _refreshAccessToken() async {
    if (_isRefreshing) {
      final received = <String>[];
      _waiters.add((token) => received.add(token));
      while (received.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return received.first;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception('Aucun refresh token disponible.');
      }

      final response = await _refreshDio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'] as String;
      await tokenStorage.saveTokens(accessToken: newAccessToken);

      for (final waiter in _waiters) {
        waiter(newAccessToken);
      }
      _waiters.clear();

      return newAccessToken;
    } finally {
      _isRefreshing = false;
    }
  }
}
