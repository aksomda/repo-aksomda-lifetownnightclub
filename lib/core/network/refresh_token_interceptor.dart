import 'dart:async';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../database/secure_token_storage.dart';

class RefreshTokenInterceptor extends Interceptor {
  final Dio dio;
  final SecureTokenStorage tokenStorage;
  Completer<String?>? _refreshCompleter;

  RefreshTokenInterceptor({required this.dio, required this.tokenStorage});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;

    if (err.response?.statusCode != 401 ||
        request.path == ApiConstants.refreshToken ||
        request.extra['skipAuthRefresh'] == true ||
        request.extra['retriedAfterRefresh'] == true) {
      handler.next(err);
      return;
    }

    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      handler.next(err);
      return;
    }

    try {
      final accessToken = await _refreshAccessToken(refreshToken);
      if (accessToken == null || accessToken.isEmpty) {
        handler.next(err);
        return;
      }

      request.extra['retriedAfterRefresh'] = true;
      request.headers['Authorization'] = 'Bearer $accessToken';
      final retryResponse = await dio.fetch<dynamic>(request);
      handler.resolve(retryResponse);
    } catch (_) {
      await tokenStorage.clear();
      handler.next(err);
    }
  }

  Future<String?> _refreshAccessToken(String refreshToken) async {
    final existing = _refreshCompleter;
    if (existing != null) {
      return existing.future;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final response = await dio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuthRefresh': true}),
      );

      final data = response.data;
      final accessToken = data is Map
          ? data['access_token']?.toString()
          : null;
      final nextRefreshToken = data is Map
          ? data['refresh_token']?.toString()
          : null;

      if (accessToken == null || accessToken.isEmpty) {
        completer.complete(null);
        return null;
      }

      await tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: nextRefreshToken ?? refreshToken,
      );
      completer.complete(accessToken);
      return accessToken;
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }
}
