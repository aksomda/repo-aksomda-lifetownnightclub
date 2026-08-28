import '../../domain/entities/waitress.dart';
import '../../domain/repositories/staff_repository.dart';
import '../datasources/staff_remote_datasource.dart';

class StaffRepositoryImpl implements StaffRepository {
  final StaffRemoteDataSource remoteDataSource;

  StaffRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<WaitressEntity>> getWaitresses() => remoteDataSource.getWaitresses();

  @override
  Future<WaitressEntity> createWaitress({required String name, String? phone}) {
    return remoteDataSource.createWaitress(name: name, phone: phone);
  }

  @override
  Future<WaitressEntity> updateWaitress({
    required String id,
    required String name,
    String? phone,
    required bool active,
  }) {
    return remoteDataSource.updateWaitress(
      id: id,
      name: name,
      phone: phone,
      active: active,
    );
  }
}
