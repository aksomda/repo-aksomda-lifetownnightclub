import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/auth_response_model.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource({required this.dio});

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // Bug corrigé : cette méthode n'acceptait que name/email/password alors
  // que `AuthRepositoryImpl.register()` et `RegisterPage` envoient aussi
  // prename/age/telephone (requis par le formulaire d'inscription et par
  // l'entité `User`). Le payload API ci-dessous doit correspondre au
  // contrat attendu côté backend (voir README).
  Future<AuthResponseModel> register({
    required String name,
    required String prename,
    required int age,
    required String telephone,
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'prename': prename,
          'age': age,
          'telephone': telephone,
          'email': email,
          'password': password,
        },
      );

      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> logout() async {
    try {
      await dio.post(ApiConstants.logout);
    } on DioException catch (e) {
      // Le logout local (suppression des tokens) doit toujours réussir,
      // même si le serveur est injoignable ; on ne relance donc l'erreur
      // que pour une vraie coupure réseau.
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
    }
  }

  Future<String?> refreshToken(String refreshToken) async {
    try {
      final response = await dio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      return response.data['access_token'] as String?;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  AppException _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException();
    }
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) {
      return const UnauthorizedException();
    }
    if (statusCode == 422 || statusCode == 400) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Données invalides.';
      return ValidationException(message);
    }
    return ServerException(e.message ?? 'Erreur serveur inconnue.');
  }
}
