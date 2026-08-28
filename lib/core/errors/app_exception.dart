class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Impossible de contacter le serveur.',
  ]);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Votre session a expiré.'])
    : super(statusCode: 401);
}

class ServerException extends AppException {
  const ServerException([
    super.message = 'Le serveur est momentanément indisponible.',
  ]);
}

class CacheException extends AppException {
  const CacheException([
    super.message = 'Aucune donnée disponible hors ligne.',
  ]);
}

class ValidationException extends AppException {
  const ValidationException.name(super.message);
}
