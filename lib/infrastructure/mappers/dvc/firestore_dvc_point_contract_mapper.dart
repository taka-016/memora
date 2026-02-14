import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';

class FirestoreDvcPointContractMapper {
  static Map<String, dynamic> toFirestore(DvcPointContract contract) {
    return {
      'groupId': contract.groupId,
      'contractName': contract.contractName,
      'contractStartYearMonth': Timestamp.fromDate(
        contract.contractStartYearMonth,
      ),
      'contractEndYearMonth': Timestamp.fromDate(contract.contractEndYearMonth),
      'useYearStartMonth': contract.useYearStartMonth,
      'annualPoint': contract.annualPoint,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
