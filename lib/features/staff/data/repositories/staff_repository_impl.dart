import '../../../../core/network/dio_client.dart';
import '../../domain/entities/waitress.dart';
import '../../domain/repositories/staff_repository.dart';
import '../datasources/staff_local_datasource.dart';
import '../datasources/staff_remote_datasource.dart';

/// Implémente le personnel avec cache de lecture et synchronisation des écritures.
class StaffRepositoryImpl implements StaffRepository {
  final StaffRemoteDataSource remote;
  final StaffLocalDataSource local;

  StaffRepositoryImpl({required this.remote, required this.local});

  @override
  Future<List<WaitressEntity>> getWaitresses() async {
    try {
      final result = await remote.getWaitresses();
      try {
        await local.saveWaitresses(result);
      } catch (_) {
        // Une panne de persistance locale ne doit pas masquer une réponse API valide.
      }
      return result;
    } catch (error) {
      final cached = local.getWaitresses();
      if (cached != null) return cached;
      throw mapDioException(error);
    }
  }

  @override
  Future<WaitressEntity> createWaitress({
    required String name,
    String? phone,
  }) async {
    try {
      final created = await remote.createWaitress(name: name, phone: phone);
      final cached = local.getWaitresses();
      try {
        await local.saveWaitresses(
          cached == null ? [created] : [...cached, created],
        );
      } catch (_) {
        // La mutation API reste réussie même si le cache local échoue.
      }
      return created;
    } catch (error) {
      throw mapDioException(error);
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
      final updated = await remote.updateWaitress(
        id: id,
        name: name,
        phone: phone,
        active: active,
      );
      final cached = local.getWaitresses();
      if (cached != null) {
        try {
          await local.saveWaitresses([
            for (final staff in cached)
              if (staff.id == id) updated else staff,
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
