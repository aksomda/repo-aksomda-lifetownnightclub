import '../../../../core/network/dio_client.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/stock_repository.dart';
import '../datasources/stock_local_datasource.dart';
import '../datasources/stock_remote_datasource.dart';
import '../models/stock_item_model.dart';

class StockRepositoryImpl implements StockRepository {
  final StockRemoteDataSource remote;
  final StockLocalDataSource local;
  StockRepositoryImpl({required this.remote, required this.local});

  @override
  Future<List<StockItemEntity>> getStocks() async {
    try {
      final r = await remote.getStocks();
      await local.saveStocks(r);
      return r;
    } catch (e) {
      // Hors-ligne (ou API en erreur) : on retombe sur le dernier stock
      // mis en cache s'il existe, sinon erreur utilisateur claire.
      if (local.hasData) return local.getStocks();
      throw mapDioException(e);
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
      // On met aussi à jour le cache pour rester cohérent hors-ligne.
      if (local.hasData) {
        final cached = local.getStocks();
        final next = <StockItemModel>[
          for (final item in cached)
            if (item.productId == productId) updated else item,
        ];
        await local.saveStocks(next);
      }
      return updated;
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
