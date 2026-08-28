import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/menu_item_model.dart';

/// Bug corrigé : ce fichier était référencé par
/// `menu_repository_impl.dart` (`import '../datasources/menu_remote_datasource.dart'`)
/// mais n'existait nulle part dans le projet -> échec de compilation.
class MenuRemoteDataSource {
  final Dio dio;

  MenuRemoteDataSource({required this.dio});

  Future<List<MenuItemModel>> getMenu() async {
    try {
      final response = await dio.get(ApiConstants.menu);
      final data = response.data as List;
      return data
          .map((json) => MenuItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
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
    return ServerException(e.message ?? 'Erreur serveur inconnue.');
  }
}
