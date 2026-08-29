/// Base des erreurs présentables à l'utilisateur.
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Impossible de contacter le serveur. Vérifiez votre connexion.',
  ]);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Votre session a expiré.'])
      : super(statusCode: 401);
}

class ForbiddenException extends AppException {
  const ForbiddenException([
    super.message = 'Vous n’êtes pas autorisé à effectuer cette action.',
  ]) : super(statusCode: 403);
}

class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'La ressource demandée est introuvable.',
  ]) : super(statusCode: 404);
}

class ServerException extends AppException {
  const ServerException([
    super.message = 'Le serveur est momentanément indisponible. Réessayez plus tard.',
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
