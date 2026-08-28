import 'package:dio/dio.dart';
// Bug corrigé : le fichier réel est dans `core/database/`, pas
// `core/storage/` (le dossier `storage` n'existe pas dans ce projet).
import '../database/secure_token_storage.dart';

/// Injecte le token JWT courant dans chaque requête sortante.
class AuthInterceptor extends Interceptor {
  final SecureTokenStorage tokenStorage;

  AuthInterceptor({required this.tokenStorage});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.getAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }
}
