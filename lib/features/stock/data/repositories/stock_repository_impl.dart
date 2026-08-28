import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/stock_repository.dart';
import '../datasources/stock_remote_datasource.dart';

class StockRepositoryImpl implements StockRepository {
  final StockRemoteDataSource remoteDataSource;

  StockRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<StockItemEntity>> getStocks() => remoteDataSource.getStocks();

  @override
  Future<StockItemEntity> updateQuantity({
    required String productId,
    required double quantity,
  }) {
    return remoteDataSource.updateQuantity(
      productId: productId,
      quantity: quantity,
    );
  }
}
