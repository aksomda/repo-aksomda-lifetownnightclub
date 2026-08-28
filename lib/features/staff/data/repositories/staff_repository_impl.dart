import '../../../../core/network/dio_client.dart';
import '../../domain/entities/waitress.dart';
import '../../domain/repositories/staff_repository.dart';
import '../datasources/staff_local_datasource.dart';
import '../datasources/staff_remote_datasource.dart';

class StaffRepositoryImpl implements StaffRepository {
  final StaffRemoteDataSource remote;
  final StaffLocalDataSource local;
  StaffRepositoryImpl({required this.remote, required this.local});

  @override
  Future<List<WaitressEntity>> getWaitresses() async {
    try {
      final r = await remote.getWaitresses();
      await local.saveWaitresses(r);
      return r;
    } catch (e) {
      // Hors-ligne (ou API en erreur) : on retombe sur le dernier
      // personnel mis en cache s'il existe, sinon erreur utilisateur claire.
      if (local.hasData) return local.getWaitresses();
      throw mapDioException(e);
    }
  }

  @override
  Future<WaitressEntity> createWaitress({
    required String name,
    String? phone,
  }) async {
    try {
      return await remote.createWaitress(name: name, phone: phone);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<WaitressEntity> updateWaitress({
    required String id,
    required String name,
    String? phone,
    required bool active,
  }) async {
    try {
      return await remote.updateWaitress(
        id: id,
        name: name,
        phone: phone,
        active: active,
      );
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
