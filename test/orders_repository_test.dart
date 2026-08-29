import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:repo_aksomda_lifetownnightclub/features/orders/data/datasources/order_local_datasource.dart';
import 'package:repo_aksomda_lifetownnightclub/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:repo_aksomda_lifetownnightclub/features/orders/data/models/order_model.dart';
import 'package:repo_aksomda_lifetownnightclub/features/orders/data/repositories/order_repository_impl.dart';
import 'package:repo_aksomda_lifetownnightclub/features/orders/domain/entities/order.dart';

class FakeRemote extends OrderRemoteDataSource {
  final List<OrderModel> items;
  bool fail = false;
  FakeRemote(this.items) : super(dio: Dio());

  @override
  Future<List<OrderModel>> getOrders() async {
    if (fail) throw Exception('offline');
    return items;
  }

  @override
  Future<OrderModel> createOrder({
    String? tableId,
    String? waitressId,
    required List<OrderItem> items,
  }) async {
    if (fail) throw Exception('offline');
    return _order('created', 'en_cours');
  }

  @override
  Future<OrderModel> updateStatus({
    required String orderId,
    required String status,
  }) async {
    if (fail) throw Exception('offline');
    return _order(orderId, status);
  }
}

OrderModel _order(String id, String status) => OrderModel(
  id: id,
  tableId: '1',
  waitressId: '1',
  status: status,
  createdAt: DateTime(2026, 1, 1),
  items: const [
    OrderItem(
      productId: '1',
      productName: 'Coca',
      quantity: 2,
      unitPrice: 500,
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => Hive.init('/tmp/lifetown_hive_tests'));
  late Box<String> box;
  late OrderLocalDataSource local;
  setUp(() async {
    box = await Hive.openBox<String>(
      'test_orders_${DateTime.now().microsecondsSinceEpoch}',
    );
    local = OrderLocalDataSource(box: box);
  });
  tearDown(() async => box.deleteFromDisk());

  test('récupère les commandes depuis l\'API', () async {
    final remote = FakeRemote([_order('1', 'en_cours')]);
    final r = OrderRepositoryImpl(remote: remote, local: local);
    final result = await r.getOrders();
    expect(result.single.id, '1');
  });

  test('met en cache les commandes après un appel réussi', () async {
    final remote = FakeRemote([_order('2', 'en_cours')]);
    final r = OrderRepositoryImpl(remote: remote, local: local);
    await r.getOrders();
    expect(local.getOrders()!.single.id, '2');
  });

  test('retourne le cache quand l\'API est injoignable (hors-ligne)', () async {
    await local.saveOrders([_order('3', 'payee')]);
    final remote = FakeRemote([])..fail = true;
    final r = OrderRepositoryImpl(remote: remote, local: local);
    expect((await r.getOrders()).single.id, '3');
  });

  test('synchronise une commande créée dans le cache', () async {
    await local.saveOrders([_order('1', 'en_cours')]);
    final remote = FakeRemote([]);
    final r = OrderRepositoryImpl(remote: remote, local: local);

    await r.createOrder(items: const []);

    expect(local.getOrders()!.map((order) => order.id), containsAll(['1', 'created']));
  });

  test('synchronise le statut modifié dans le cache', () async {
    await local.saveOrders([_order('1', 'en_cours')]);
    final remote = FakeRemote([]);
    final r = OrderRepositoryImpl(remote: remote, local: local);

    await r.updateOrderStatus(orderId: '1', status: 'payee');

    expect(local.getOrders()!.single.status, 'payee');
  });

  test('remonte une erreur utilisateur si API et cache sont vides', () async {
    final remote = FakeRemote([])..fail = true;
    final r = OrderRepositoryImpl(remote: remote, local: local);
    expect(r.getOrders(), throwsException);
  });
}
