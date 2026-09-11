import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_contract_repository.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/dvc/sqlite_dvc_point_contract_mapper.dart';

class SqliteDvcPointContractRepository implements DvcPointContractRepository {
  SqliteDvcPointContractRepository(this.db);
  final OfflineDatabase db;
  @override
  Future<void> saveDvcPointContract(DvcPointContract value) async =>
      db.insertRow(
        'dvc_point_contracts',
        SqliteDvcPointContractMapper.toRow(
          value.copyWith(id: const Uuid().v4()),
        ),
      );
  @override
  Future<void> deleteDvcPointContract(String id) async =>
      db.deleteRows('dvc_point_contracts', 'id', id);
  @override
  Future<void> deleteDvcPointContractsByGroupId(String groupId) async =>
      db.deleteRows('dvc_point_contracts', 'group_id', groupId);
}
