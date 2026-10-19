import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';

abstract class DvcPointContractRepository {
  Future<void> saveDvcPointContracts(
    String groupId,
    List<DvcPointContract> contracts, {
    Map<String, int> expectedVersions = const {},
    List<DvcPointContract> originalContracts = const [],
  });
  Future<void> saveDvcPointContract(DvcPointContract contract);
  Future<void> deleteDvcPointContract(
    String contractId, {
    int? expectedVersion,
  });
  Future<void> deleteDvcPointContractsByGroupId(String groupId);
}
