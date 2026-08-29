import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_aksomda_lifetownnightclub/core/database/secure_token_storage.dart';
import 'package:repo_aksomda_lifetownnightclub/core/network/dio_client.dart';

class MemoryTokenStorage extends SecureTokenStorage {
  String? access;
  String? refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    access = accessToken;
    if (refreshToken != null) refresh = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => access;

  @override
  Future<String?> getRefreshToken() async => refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

class FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int protectedCalls = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.path == '/protected' && protectedCalls++ == 0) {
      return ResponseBody.fromString(
        '{"detail":"expired"}',
        401,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    if (options.path == '/auth/refresh') {
      return ResponseBody.fromString(
        '{"access_token":"new-access","refresh_token":"new-refresh","user":{}}',
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

void main() {
  test('n injecte pas le JWT sur login', () async {
    final storage = MemoryTokenStorage()..access = 'old-access';
    final client = DioClient(tokenStorage: storage);
    final adapter = FakeAdapter();
    client.dio.httpClientAdapter = adapter;

    await client.dio.post('/auth/login');

    expect(adapter.requests.single.headers['Authorization'], isNull);
  });

  test('rafraîchit le JWT puis rejoue une requête 401', () async {
    final storage = MemoryTokenStorage()
      ..access = 'old-access'
      ..refresh = 'old-refresh';
    final client = DioClient(tokenStorage: storage);
    final adapter = FakeAdapter();
    client.dio.httpClientAdapter = adapter;

    await client.dio.get('/protected');

    expect(storage.access, 'new-access');
    expect(storage.refresh, 'new-refresh');
    expect(
      adapter.requests.where((request) => request.path == '/protected').length,
      2,
    );
    expect(
      adapter.requests.last.headers['Authorization'],
      'Bearer new-access',
    );
  });

  test('n envoie pas le refresh token au mécanisme de refresh', () async {
    final storage = MemoryTokenStorage()..refresh = 'refresh';
    final client = DioClient(tokenStorage: storage);
    final adapter = FakeAdapter();
    client.dio.httpClientAdapter = adapter;

    await client.dio.post('/auth/refresh');

    final request = adapter.requests.single;
    expect(request.headers['Authorization'], isNull);
  });
}
