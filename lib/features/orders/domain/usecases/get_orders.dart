import '../entities/order.dart';import '../repositories/order_repository.dart';class GetOrders{final OrderRepository r;GetOrders(this.r);Future<List<OrderEntity>> call()=>r.getOrders();}
