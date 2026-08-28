import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/order.dart';
import '../models/order_model.dart';

class OrderRemoteDataSource {
  final Dio dio;
  OrderRemoteDataSource({required this.dio});

  Future<List<OrderModel>> getOrders() async {
    final d = (await dio.get(ApiConstants.orders)).data;
    final l = d is Map && d['data'] is List ? d['data'] as List : d as List;
    return l
        .whereType<Map>()
        .map((x) => OrderModel.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  Future<OrderModel> createOrder({
    String? tableId,
    String? waitressId,
    required List<OrderItem> items,
  }) async {
    final r = await dio.post(
      ApiConstants.orders,
      data: {
        'table_id': tableId,
        'waitress_id': waitressId,
        'items': items
            .map(
              (i) => {
                'product_id': i.productId,
                'quantity': i.quantity,
                'unit_price': i.unitPrice,
              },
            )
            .toList(),
      },
    );
    return OrderModel.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<OrderModel> updateStatus({
    required String orderId,
    required String status,
  }) async {
    final r = await dio.patch(
      '${ApiConstants.orders}/$orderId/status',
      data: {'status': status},
    );
    return OrderModel.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}
