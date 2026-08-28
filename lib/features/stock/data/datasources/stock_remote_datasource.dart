// Ajouté : la feature "stock" n'avait ni datasource ni repository
// implémenté, seulement une entité et une interface abstraite.
import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/stock_item.dart';

class StockRemoteDataSource {
  final Dio dio;

  StockRemoteDataSource({required this.dio});

  Future<List<StockItemEntity>> getStocks() async {
    try {
      final response = await dio.get(ApiConstants.stocks);
      final data = response.data as List;
      return data.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<StockItemEntity> updateQuantity({
    required String productId,
    required double quantity,
  }) async {
    try {
      final response = await dio.patch(
        '${ApiConstants.stocks}/$productId',
        data: {'quantity': quantity},
      );
      return _fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  StockItemEntity _fromJson(Map<String, dynamic> json) {
    return StockItemEntity(
      productId: json['product_id'].toString(),
      productName: json['product_name'] as String? ?? '',
      quantity: (json['quantity'] as num).toDouble(),
      minimumQuantity: (json['minimum_quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'unité(s)',
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
