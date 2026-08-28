import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../database/secure_token_storage.dart';
import '../errors/app_exception.dart';
import 'auth_interceptor.dart';
import 'refresh_token_interceptor.dart';

class DioClient {
  final Dio dio;
  DioClient({required SecureTokenStorage tokenStorage}) : dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10), sendTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  )) {
    dio.interceptors.add(AuthInterceptor(tokenStorage: tokenStorage));
    dio.interceptors.add(RefreshTokenInterceptor(dio: dio, tokenStorage: tokenStorage));
  }
}

AppException mapDioException(Object error) {
  if (error is DioException) {
    if (error.response?.statusCode == 401) return const UnauthorizedException();
    if (error.response?.statusCode != null && error.response!.statusCode! >= 500) return const ServerException();
    if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout || error.type == DioExceptionType.receiveTimeout) return const NetworkException();
    final data = error.response?.data;
    if (data is Map && data['message'] != null) return AppException(data['message'].toString(), statusCode: error.response?.statusCode);
  }
  return AppException(error.toString());
}
