import '../entities/table_entity.dart';

abstract class TableRepository {
  Future<List<TableEntity>> getTables();

  Future<TableEntity> updateStatus({
    required String tableId,
    required String status,
  });
}
