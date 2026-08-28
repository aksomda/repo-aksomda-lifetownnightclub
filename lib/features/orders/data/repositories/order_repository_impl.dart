import '../../../../core/network/dio_client.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_local_datasource.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remote;
  final OrderLocalDataSource local;
  OrderRepositoryImpl({required this.remote, required this.local});

  @override
  Future<List<OrderEntity>> getOrders() async {
    try {
      final r = await remote.getOrders();
      await local.saveOrders(r);
      return r;
    } catch (e) {
      // Hors-ligne (ou API en erreur) : on retombe sur les dernières
      // commandes mises en cache s'il y en a, sinon erreur utilisateur claire.
      if (local.hasData) return local.getOrders();
      throw mapDioException(e);
    }
  }

  @override
  Future<OrderEntity> createOrder({
    String? tableId,
    String? waitressId,
    required List<OrderItem> items,
  }) async {
    try {
      return await remote.createOrder(
        tableId: tableId,
        waitressId: waitressId,
        items: items,
      );
    } catch (e) {
      // La création d'une commande nécessite le réseau : impossible de
      // fonctionner hors-ligne pour une écriture, on remonte juste
      // un message d'erreur clair.
      throw mapDioException(e);
    }
  }

  @override
  Future<OrderEntity> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      return await remote.updateStatus(orderId: orderId, status: status);
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
