import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:repo_aksomda_lifetownnightclub/features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'package:repo_aksomda_lifetownnightclub/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:repo_aksomda_lifetownnightclub/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:repo_aksomda_lifetownnightclub/features/dashboard/data/repositories/dashboard_repository_impl.dart';

class FakeDashboardRemote extends DashboardRemoteDataSource {
  final DashboardSummaryModel summary;
  bool fail = false;

  FakeDashboardRemote(this.summary) : super(Dio());

  @override
  Future<DashboardSummaryModel> getSummary() async {
    if (fail) throw Exception('offline');
    return summary;
  }
}

const initial = DashboardSummaryModel(
  products: 12,
  orders: 25,
  lowStocks: 2,
  staff: 5,
  revenue: 125000,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => Hive.init('/tmp/lifetown_dashboard_tests'));

  late Box<String> box;
  late DashboardLocalDataSource local;

  setUp(() async {
    box = await Hive.openBox<String>(
      'dashboard_${DateTime.now().microsecondsSinceEpoch}',
    );
    local = DashboardLocalDataSource(box: box);
  });

  tearDown(() async => box.deleteFromDisk());

  test('charge le dashboard depuis l API et le met en cache', () async {
    final repository = DashboardRepositoryImpl(
      remote: FakeDashboardRemote(initial),
      local: local,
    );

    final result = await repository.getSummary();

    expect(result.orders, 25);
    expect(local.getSummary()!.revenue, 125000);
  });

  test('retourne le dernier dashboard en cache hors ligne', () async {
    await local.saveSummary(initial);
    final repository = DashboardRepositoryImpl(
      remote: FakeDashboardRemote(initial)..fail = true,
      local: local,
    );

    final result = await repository.getSummary();

    expect(result.products, 12);
  });

  test('retourne une erreur si API et cache sont absents', () async {
    final repository = DashboardRepositoryImpl(
      remote: FakeDashboardRemote(initial)..fail = true,
      local: local,
    );

    expect(repository.getSummary(), throwsA(isA<Exception>()));
  });

  test('ignore un cache JSON corrompu', () async {
    await box.put(DashboardLocalDataSource.key, '{invalid-json');
    expect(local.getSummary(), isNull);
    expect(local.hasData, isFalse);
  });
}
