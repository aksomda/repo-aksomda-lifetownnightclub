import '../../../../core/network/dio_client.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/stock_repository.dart';
import '../datasources/stock_local_datasource.dart';
import '../datasources/stock_remote_datasource.dart';
import '../models/stock_item_model.dart';

/// Implémente le stock avec cache de lecture et synchronisation des mises à jour.
class StockRepositoryImpl implements StockRepository {
  final StockRemoteDataSource remote;
  final StockLocalDataSource local;

  StockRepositoryImpl({required this.remote, required this.local});

  @override
  Future<List<StockItemEntity>> getStocks() async {
    try {
      final result = await remote.getStocks();
      try {
        await local.saveStocks(result);
      } catch (_) {
        // Une panne de persistance locale ne doit pas masquer une réponse API valide.
      }
      return result;
    } catch (error) {
      final cached = local.getStocks();
      if (cached != null) return cached;
      throw mapDioException(error);
    }
  }

  @override
  Future<StockItemEntity> updateQuantity({
    required String productId,
    required double quantity,
  }) async {
    try {
      final updated = await remote.updateQuantity(
        productId: productId,
        quantity: quantity,
      );
      final cached = local.getStocks();
      if (cached != null) {
        try {
          await local.saveStocks([
            for (final item in cached)
              if (item.productId == productId) updated else item,
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
