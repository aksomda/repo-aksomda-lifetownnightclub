import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../database/secure_token_storage.dart';

/// Injecte le JWT sur les requêtes protégées uniquement.
class AuthInterceptor extends Interceptor {
  final SecureTokenStorage tokenStorage;

  AuthInterceptor({required this.tokenStorage});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final skipAuth = options.extra['skipAuth'] == true;
    final isPublicAuthRoute =
        options.path == ApiConstants.login ||
        options.path == ApiConstants.register ||
        options.path == ApiConstants.refreshToken;

    if (!skipAuth && !isPublicAuthRoute) {
      final token = await tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }
}
