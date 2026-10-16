import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';

abstract class DvcPointContractRepository {
  Future<void> saveDvcPointContracts(
    String groupId,
    List<DvcPointContract> contracts,
  );
  Future<void> saveDvcPointContract(DvcPointContract contract);
  Future<void> deleteDvcPointContract(String contractId);
  Future<void> deleteDvcPointContractsByGroupId(String groupId);
}
