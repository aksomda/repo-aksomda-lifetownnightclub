import '../entities/stock_item.dart';import '../repositories/stock_repository.dart';class GetStocks{final StockRepository r;GetStocks(this.r);Future<List<StockItemEntity>> call()=>r.getStocks();}
