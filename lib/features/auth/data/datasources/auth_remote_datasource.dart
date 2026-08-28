import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/auth_response_model.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource({required this.dio});

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return AuthResponseModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AuthResponseModel> register({
    required String name,
    required String prename,
    required int age,
    required String telephone,
    required String email,
    required String password,
  }) async {
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
    return AuthResponseModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AuthResponseModel> refreshToken({
    required String refreshToken,
  }) async {
    final response = await dio.post(
      ApiConstants.refreshToken,
      data: {'refresh_token': refreshToken},
      options: Options(extra: {'skipAuthRefresh': true}),
    );
    return AuthResponseModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> logout() async {
    await dio.post(ApiConstants.logout);
  }
}
