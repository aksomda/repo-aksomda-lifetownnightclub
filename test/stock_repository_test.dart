import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:repo_aksomda_lifetownnightclub/features/stock/data/datasources/stock_local_datasource.dart';
import 'package:repo_aksomda_lifetownnightclub/features/stock/data/datasources/stock_remote_datasource.dart';
import 'package:repo_aksomda_lifetownnightclub/features/stock/data/models/stock_item_model.dart';
import 'package:repo_aksomda_lifetownnightclub/features/stock/data/repositories/stock_repository_impl.dart';

class FakeRemote extends StockRemoteDataSource {
  final List<StockItemModel> items;
  bool fail = false;
  FakeRemote(this.items) : super(dio: Dio());

  @override
  Future<List<StockItemModel>> getStocks() async {
    if (fail) throw Exception('offline');
    return items;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => Hive.init('/tmp/lifetown_hive_tests'));
  late Box<String> box;
  late StockLocalDataSource local;
  setUp(() async {
    box = await Hive.openBox<String>(
      'test_stock_${DateTime.now().microsecondsSinceEpoch}',
    );
    local = StockLocalDataSource(box: box);
  });
  tearDown(() async => box.deleteFromDisk());

  test('récupère les stocks depuis l\'API', () async {
    final remote = FakeRemote([
      const StockItemModel(
        productId: '1',
        productName: 'Sobbra',
        quantity: 50,
        minimumQuantity: 10,
        unit: 'bouteille',
      ),
    ]);
    final r = StockRepositoryImpl(remote: remote, local: local);
    final result = await r.getStocks();
    expect(result.single.productName, 'Sobbra');
  });

  test('met en cache les stocks après un appel réussi', () async {
    final remote = FakeRemote([
      const StockItemModel(
        productId: '1',
        productName: 'Coca',
        quantity: 80,
        minimumQuantity: 10,
        unit: 'bouteille',
      ),
    ]);
    final r = StockRepositoryImpl(remote: remote, local: local);
    await r.getStocks();
    expect(local.getStocks().single.productName, 'Coca');
  });

  test('retourne le cache quand l\'API est injoignable (hors-ligne)', () async {
    await local.saveStocks([
      const StockItemModel(
        productId: '1',
        productName: 'Fanta',
        quantity: 40,
        minimumQuantity: 10,
        unit: 'bouteille',
      ),
    ]);
    final remote = FakeRemote([])..fail = true;
    final r = StockRepositoryImpl(remote: remote, local: local);
    expect((await r.getStocks()).single.productName, 'Fanta');
  });

  test('remonte une erreur utilisateur si API et cache sont vides', () async {
    final remote = FakeRemote([])..fail = true;
    final r = StockRepositoryImpl(remote: remote, local: local);
    expect(r.getStocks(), throwsException);
  });
}
