import '../../../../core/network/dio_client.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_local_datasource.dart';
import '../datasources/order_remote_datasource.dart';

/// Implémente les commandes avec cache de lecture et synchronisation des écritures.
class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remote;
  final OrderLocalDataSource local;

  OrderRepositoryImpl({required this.remote, required this.local});

  @override
  Future<List<OrderEntity>> getOrders() async {
    try {
      final result = await remote.getOrders();
      try {
        await local.saveOrders(result);
      } catch (_) {
        // Une panne de persistance locale ne doit pas masquer une réponse API valide.
      }
      return result;
    } catch (error) {
      final cached = local.getOrders();
      if (cached != null) return cached;
      throw mapDioException(error);
    }
  }

  @override
  Future<OrderEntity> createOrder({
    String? tableId,
    String? waitressId,
    required List<OrderItem> items,
  }) async {
    try {
      final created = await remote.createOrder(
        tableId: tableId,
        waitressId: waitressId,
        items: items,
      );
      final cached = local.getOrders();
      try {
        await local.saveOrders(
          cached == null ? [created] : [...cached, created],
        );
      } catch (_) {
        // La mutation API reste réussie même si le cache local échoue.
      }
      return created;
    } catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<OrderEntity> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final updated = await remote.updateStatus(
        orderId: orderId,
        status: status,
      );
      final cached = local.getOrders();
      if (cached != null) {
        try {
          await local.saveOrders([
            for (final order in cached)
              if (order.id == orderId) updated else order,
          ]);
        } catch (_) {
          // La mutation API reste réussie même si le cache local échoue.
        }
      }
      return updated;
    } catch (error) {
      throw mapDioException(error);
    }
  }
}
