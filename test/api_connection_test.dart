import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_aksomda_lifetownnightclub/core/database/secure_token_storage.dart';
import 'package:repo_aksomda_lifetownnightclub/core/network/dio_client.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/data/repositories/auth_repository_impl.dart';

class FakeAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      '{"access_token":"api-token","refresh_token":"api-refresh","user":{"id":1,"name":"Somda","prename":"Clément","age":30,"telephone":"70000000","email":"admin@lifetown.com"}}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('connexion Flutter API via Dio, interceptor et repository', () async {
    final storage = SecureTokenStorage();
    await storage.saveTokens(
      accessToken: 'existing-token',
      refreshToken: 'refresh-token',
    );

    final client = DioClient(tokenStorage: storage);
    final adapter = FakeAdapter();
    client.dio.httpClientAdapter = adapter;

    final repository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSource(dio: client.dio),
      tokenStorage: storage,
    );

    final user = await repository.login(
      email: 'admin@lifetown.com',
      password: 'password',
    );

    expect(user.email, 'admin@lifetown.com');
    expect(adapter.lastRequest?.headers['Authorization'], isNull);
    expect(await storage.getAccessToken(), 'api-token');
    expect(await storage.getRefreshToken(), 'api-refresh');
  });
}
