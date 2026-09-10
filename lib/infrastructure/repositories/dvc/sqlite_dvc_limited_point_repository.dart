import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/dvc/sqlite_dvc_limited_point_mapper.dart';

class SqliteDvcLimitedPointRepository implements DvcLimitedPointRepository {
  SqliteDvcLimitedPointRepository(this.db);
  final OfflineDatabase db;
  @override
  Future<void> saveDvcLimitedPoint(DvcLimitedPoint value) async => db.insertRow('dvc_limited_points', SqliteDvcLimitedPointMapper.toRow(value.copyWith(id: const Uuid().v4())));
  @override
  Future<void> deleteDvcLimitedPoint(String id) async => db.deleteRows('dvc_limited_points', 'id', id);
  @override
  Future<void> deleteDvcLimitedPointsByGroupId(String groupId) async => db.deleteRows('dvc_limited_points', 'group_id', groupId);
}
