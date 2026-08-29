import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:repo_aksomda_lifetownnightclub/features/staff/data/datasources/staff_local_datasource.dart';
import 'package:repo_aksomda_lifetownnightclub/features/staff/data/datasources/staff_remote_datasource.dart';
import 'package:repo_aksomda_lifetownnightclub/features/staff/data/models/waitress_model.dart';
import 'package:repo_aksomda_lifetownnightclub/features/staff/data/repositories/staff_repository_impl.dart';

class FakeStaffRemote extends StaffRemoteDataSource {
  final List<WaitressModel> items;
  bool fail = false;

  FakeStaffRemote(this.items) : super(Dio());

  @override
  Future<List<WaitressModel>> getWaitresses() async {
    if (fail) throw Exception('offline');
    return items;
  }

  @override
  Future<WaitressModel> createWaitress({
    required String name,
    String? phone,
  }) async {
    if (fail) throw Exception('offline');
    return WaitressModel(
      id: 'new',
      name: name,
      phone: phone,
      active: true,
    );
  }

  @override
  Future<WaitressModel> updateWaitress({
    required String id,
    required String name,
    String? phone,
    required bool active,
  }) async {
    if (fail) throw Exception('offline');
    return WaitressModel(
      id: id,
      name: name,
      phone: phone,
      active: active,
    );
  }
}

WaitressModel staff(String id, String name) =>
    WaitressModel(id: id, name: name, phone: '70000000', active: true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => Hive.init('/tmp/lifetown_staff_tests'));

  late Box<String> box;
  late StaffLocalDataSource local;

  setUp(() async {
    box = await Hive.openBox<String>(
      'staff_${DateTime.now().microsecondsSinceEpoch}',
    );
    local = StaffLocalDataSource(box: box);
  });

  tearDown(() async => box.deleteFromDisk());

  test('charge le personnel et actualise le cache', () async {
    final repository = StaffRepositoryImpl(
      remote: FakeStaffRemote([staff('1', 'Awa')]),
      local: local,
    );

    final result = await repository.getWaitresses();

    expect(result.single.name, 'Awa');
    expect(local.getWaitresses()!.single.name, 'Awa');
  });

  test('retourne le cache hors ligne', () async {
    await local.saveWaitresses([staff('1', 'Awa')]);
    final repository = StaffRepositoryImpl(
      remote: FakeStaffRemote([])..fail = true,
      local: local,
    );

    final result = await repository.getWaitresses();

    expect(result.single.name, 'Awa');
  });

  test('crée une serveuse et synchronise le cache', () async {
    await local.saveWaitresses([staff('1', 'Awa')]);
    final repository = StaffRepositoryImpl(
      remote: FakeStaffRemote([]),
      local: local,
    );

    await repository.createWaitress(name: 'Mariam', phone: '71000000');

    expect(local.getWaitresses()!.map((item) => item.name), containsAll([
      'Awa',
      'Mariam',
    ]));
  });

  test('met à jour une serveuse et synchronise le cache', () async {
    await local.saveWaitresses([staff('1', 'Awa')]);
    final repository = StaffRepositoryImpl(
      remote: FakeStaffRemote([]),
      local: local,
    );

    await repository.updateWaitress(
      id: '1',
      name: 'Awa Traore',
      phone: '72000000',
      active: false,
    );

    final updated = local.getWaitresses()!.single;
    expect(updated.name, 'Awa Traore');
    expect(updated.active, isFalse);
  });

  test('remonte une AppException sans cache', () async {
    final repository = StaffRepositoryImpl(
      remote: FakeStaffRemote([])..fail = true,
      local: local,
    );

    expect(repository.getWaitresses(), throwsA(isA<Exception>()));
  });
}
