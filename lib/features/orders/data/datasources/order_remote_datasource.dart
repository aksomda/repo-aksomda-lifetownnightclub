import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/order.dart';

class OrderRemoteDataSource {
  final Dio dio;

  OrderRemoteDataSource({required this.dio});

  Future<List<OrderEntity>> getOrders() async {
    final response = await dio.get(ApiConstants.orders);

    final data = response.data as List;

    return data.map((json) {
      return _fromJson(json as Map<String, dynamic>);
    }).toList();
  }

  Future<OrderEntity> createOrder({
    String? tableId,
    String? waitressId,
    required List<OrderItem> items,
  }) async {
    final response = await dio.post(
      ApiConstants.orders,
      data: {
        'table_id': tableId,
        'waitress_id': waitressId,
        'items': items.map((item) {
          return {
            'product_id': item.productId,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
          };
        }).toList(),
      },
    );

    return _fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrderEntity> updateStatus({
    required String orderId,
    required String status,
  }) async {
    final response = await dio.patch(
      '${ApiConstants.orders}/$orderId/status',
      data: {'status': status},
    );

    return _fromJson(response.data as Map<String, dynamic>);
  }

  OrderEntity _fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .map(
          (item) => OrderItem(
            productId: item['product_id'].toString(),
            productName: item['product_name'] as String? ?? '',
            quantity: item['quantity'] as int,
            unitPrice: (item['unit_price'] as num).toDouble(),
          ),
        )
        .toList();

    return OrderEntity(
      id: json['id'].toString(),
      tableId: json['table_id']?.toString(),
      waitressId: json['waitress_id']?.toString(),
      items: items,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
