import '../entities/order.dart';

abstract class OrderRepository {
  Future<List<OrderEntity>> getOrders();

  Future<OrderEntity> createOrder({
    String? tableId,
    String? waitressId,
    required List<OrderItem> items,
  });

  Future<OrderEntity> updateOrderStatus({
    required String orderId,
    required String status,
  });
}
