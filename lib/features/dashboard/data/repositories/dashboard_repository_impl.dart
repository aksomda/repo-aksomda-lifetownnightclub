import '../../../../core/network/dio_client.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remote;
  final DashboardLocalDataSource local;
  DashboardRepositoryImpl({required this.remote, required this.local});

  @override
  Future<DashboardSummary> getSummary() async {
    try {
      final r = await remote.getSummary();
      await local.saveSummary(r);
      return r;
    } catch (e) {
      // Hors-ligne (ou API en erreur) : on retombe sur le dernier résumé
      // mis en cache s'il existe, sinon erreur utilisateur claire.
      final cached = local.getSummary();
      if (cached != null) return cached;
      throw mapDioException(e);
    }
  }
}
