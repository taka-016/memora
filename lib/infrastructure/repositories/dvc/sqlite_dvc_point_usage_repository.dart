import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/dvc/sqlite_dvc_point_usage_mapper.dart';

class SqliteDvcPointUsageRepository implements DvcPointUsageRepository {
  SqliteDvcPointUsageRepository(this.db);
  final OfflineDatabase db;
  @override
  Future<void> saveDvcPointUsage(DvcPointUsage value) async => db.insertRow(
    'dvc_point_usages',
    SqliteDvcPointUsageMapper.toRow(value.copyWith(id: const Uuid().v4())),
  );
  @override
  Future<void> deleteDvcPointUsage(String id) async =>
      db.deleteRows('dvc_point_usages', 'id', id);
  @override
  Future<void> deleteDvcPointUsagesByGroupId(String groupId) async =>
      db.deleteRows('dvc_point_usages', 'group_id', groupId);
}
