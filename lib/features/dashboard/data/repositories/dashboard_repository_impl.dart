import '../../../../core/network/dio_client.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';
import '../datasources/dashboard_remote_datasource.dart';

/// Implémente le tableau de bord avec stratégie réseau puis cache.
class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remote;
  final DashboardLocalDataSource local;

  DashboardRepositoryImpl({required this.remote, required this.local});

  @override
  Future<DashboardSummary> getSummary() async {
    try {
      final result = await remote.getSummary();
      try {
        await local.saveSummary(result);
      } catch (_) {
        // Une panne de persistance locale ne doit pas masquer une réponse API valide.
      }
      return result;
    } catch (error) {
      final cached = local.getSummary();
      if (cached != null) return cached;
      throw mapDioException(error);
    }
  }
}
