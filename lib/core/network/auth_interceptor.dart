import 'package:dio/dio.dart';
import '../database/secure_token_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureTokenStorage tokenStorage;
  AuthInterceptor({required this.tokenStorage});

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }
}
