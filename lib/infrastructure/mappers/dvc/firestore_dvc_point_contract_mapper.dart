import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';

class FirestoreDvcPointContractMapper {
  static final _defaultDate = DateTime.fromMillisecondsSinceEpoch(0);

  static DvcPointContractDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DvcPointContractDto(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      contractName: data['contractName'] as String? ?? '',
      contractStartYearMonth:
          (data['contractStartYearMonth'] as Timestamp?)?.toDate() ??
          _defaultDate,
      contractEndYearMonth:
          (data['contractEndYearMonth'] as Timestamp?)?.toDate() ??
          _defaultDate,
      useYearStartMonth: _asInt(data['useYearStartMonth']),
      annualPoint: _asInt(data['annualPoint']),
    );
  }

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

  static int _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
