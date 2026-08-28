import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/stock_item_model.dart';

class StockRemoteDataSource {
  final Dio dio;
  StockRemoteDataSource({required this.dio});

  Future<List<StockItemModel>> getStocks() async {
    final d = (await dio.get(ApiConstants.stocks)).data;
    final l = d is Map && d['data'] is List ? d['data'] as List : d as List;
    return l
        .whereType<Map>()
        .map((x) => StockItemModel.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  Future<StockItemModel> updateQuantity({
    required String productId,
    required double quantity,
  }) async {
    final r = await dio.patch(
      '${ApiConstants.stocks}/$productId',
      data: {'quantity': quantity},
    );
    return StockItemModel.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}
