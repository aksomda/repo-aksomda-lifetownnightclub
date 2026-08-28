// Ajouté : la feature "staff" (serveuses) n'avait ni datasource ni
// repository implémenté.
import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/waitress.dart';

class StaffRemoteDataSource {
  final Dio dio;

  StaffRemoteDataSource({required this.dio});

  Future<List<WaitressEntity>> getWaitresses() async {
    try {
      final response = await dio.get(ApiConstants.staff);
      final data = response.data as List;
      return data.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<WaitressEntity> createWaitress({
    required String name,
    String? phone,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.staff,
        data: {'name': name, 'phone': phone},
      );
      return _fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<WaitressEntity> updateWaitress({
    required String id,
    required String name,
    String? phone,
    required bool active,
  }) async {
    try {
      final response = await dio.put(
        '${ApiConstants.staff}/$id',
        data: {'name': name, 'phone': phone, 'active': active},
      );
      return _fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  WaitressEntity _fromJson(Map<String, dynamic> json) {
    return WaitressEntity(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }

  AppException _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException();
    }
    return ServerException(e.message ?? 'Erreur serveur inconnue.');
  }
}
