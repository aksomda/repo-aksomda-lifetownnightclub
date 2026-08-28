// Ajouté : le repository "orders" n'existait qu'en interface abstraite
// (`domain/repositories/order_repository.dart`) — sans implémentation,
// impossible d'afficher un vrai écran "Commandes" branché sur l'API.
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<OrderEntity>> getOrders() => remoteDataSource.getOrders();

  @override
  Future<OrderEntity> createOrder({
    String? tableId,
    String? waitressId,
    required List<OrderItem> items,
  }) {
    return remoteDataSource.createOrder(
      tableId: tableId,
      waitressId: waitressId,
      items: items,
    );
  }

  @override
  Future<OrderEntity> updateOrderStatus({
    required String orderId,
    required String status,
  }) {
    return remoteDataSource.updateStatus(orderId: orderId, status: status);
  }
}
