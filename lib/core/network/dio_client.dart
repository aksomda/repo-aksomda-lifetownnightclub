import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../database/secure_token_storage.dart';
import '../errors/app_exception.dart';
import 'auth_interceptor.dart';
import 'refresh_token_interceptor.dart';

/// Crée le client HTTP centralisé et traduit les erreurs réseau en erreurs métier.
class DioClient {
  final Dio dio;

  DioClient({required SecureTokenStorage tokenStorage})
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(AuthInterceptor(tokenStorage: tokenStorage));
    dio.interceptors.add(
      RefreshTokenInterceptor(dio: dio, tokenStorage: tokenStorage),
    );
  }
}

/// Convertit une erreur Dio ou applicative en message sûr et compréhensible.
AppException mapDioException(Object error) {
  if (error is AppException) {
    return error;
  }

  if (error is DioException) {
    final status = error.response?.statusCode;
    final data = error.response?.data;

    if (status == 401) {
      return const UnauthorizedException();
    }

    if (status == 403) {
      return const ForbiddenException();
    }

    if (status == 404) {
      return const NotFoundException();
    }

    if (status == 409) {
      return AppException(
        extractServerMessage(data) ?? 'Cette opération ne peut pas être effectuée.',
        statusCode: status,
      );
    }

    if (status == 422) {
      return AppException(
        extractServerMessage(data) ?? 'Les données envoyées sont invalides.',
        statusCode: status,
      );
    }

    if (status != null && status >= 500) {
      return const ServerException();
    }

    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkException();
      case DioExceptionType.badCertificate:
        return const NetworkException(
          'La connexion sécurisée au serveur a échoué.',
        );
      case DioExceptionType.cancel:
        return const NetworkException('La requête a été annulée.');
      case DioExceptionType.badResponse:
        return AppException(
          extractServerMessage(data) ?? 'Le serveur a refusé la requête.',
          statusCode: status,
        );
      case DioExceptionType.unknown:
        return const NetworkException();
    }
  }

  return const AppException(
    'Une erreur inattendue est survenue. Veuillez réessayer.',
  );
}

/// Extrait un message utile depuis les formats d'erreur API les plus courants.
String? extractServerMessage(Object? data) {
  if (data is! Map) return null;

  final message = data['message'] ?? data['error'];
  if (message is String && message.trim().isNotEmpty) {
    return message.trim();
  }

  final detail = data['detail'];
  if (detail is String && detail.trim().isNotEmpty) {
    return detail.trim();
  }

  if (detail is List && detail.isNotEmpty) {
    final first = detail.first;
    if (first is Map && first['msg'] is String) {
      return first['msg'].toString();
    }
  }

  return null;
}
