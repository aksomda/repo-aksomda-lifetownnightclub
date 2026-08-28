import 'package:dio/dio.dart';
import '../database/secure_token_storage.dart';

import '../constants/api_constants.dart';
import 'auth_interceptor.dart';
import 'refresh_token_interceptor.dart';

class DioClient {
  final Dio dio;

  DioClient({required SecureTokenStorage tokenStorage})
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(AuthInterceptor(tokenStorage: tokenStorage));
    // Ajouté : le fichier existait mais était vide, donc aucun
    // rafraîchissement de token n'était jamais réellement branché.
    dio.interceptors.add(RefreshTokenInterceptor(tokenStorage: tokenStorage));

    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
}
