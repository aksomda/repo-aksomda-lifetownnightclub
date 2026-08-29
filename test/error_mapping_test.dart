import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_aksomda_lifetownnightclub/core/errors/app_exception.dart';
import 'package:repo_aksomda_lifetownnightclub/core/network/dio_client.dart';

DioException dioError(int status, Object data) => DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: status,
        data: data,
      ),
    );

void main() {
  test('mappe 401 en expiration de session', () {
    expect(mapDioException(dioError(401, {})), isA<UnauthorizedException>());
  });

  test('mappe 403 en accès interdit', () {
    expect(mapDioException(dioError(403, {})), isA<ForbiddenException>());
  });

  test('conserve le message API pour 409', () {
    final exception = mapDioException(
      dioError(409, {'message': 'Stock insuffisant'}),
    );

    expect(exception.message, 'Stock insuffisant');
  });

  test('mappe les erreurs de validation FastAPI', () {
    final exception = mapDioException(
      dioError(422, {
        'detail': [
          {'msg': 'field required'},
        ],
      }),
    );

    expect(exception.message, 'field required');
  });

  test('ne divulgue pas la stack technique pour une erreur inconnue', () {
    final exception = mapDioException(StateError('internal details'));

    expect(exception.message, contains('erreur inattendue'));
    expect(exception.message, isNot(contains('internal details')));
  });

  test('mappe un timeout en erreur réseau', () {
    final exception = mapDioException(
      DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    expect(exception, isA<NetworkException>());
  });
}
