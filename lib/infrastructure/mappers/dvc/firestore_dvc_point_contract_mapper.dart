import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/infrastructure/mappers/firestore_mapper_value_parser.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

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
          FirestoreMapperValueParser.asDateTime(
            data['contractStartYearMonth'],
          ) ??
          _defaultDate,
      contractEndYearMonth:
          FirestoreMapperValueParser.asDateTime(data['contractEndYearMonth']) ??
          _defaultDate,
      useYearStartMonth: FirestoreMapperValueParser.asInt(
        data['useYearStartMonth'],
      ),
      annualPoint: FirestoreMapperValueParser.asInt(data['annualPoint']),
    );
  }

  static Map<String, dynamic> toCreateFirestore(DvcPointContract contract) {
    return {
      'groupId': contract.groupId,
      'contractName': contract.contractName,
      'contractStartYearMonth': Timestamp.fromDate(
        contract.contractStartYearMonth,
      ),
      'contractEndYearMonth': Timestamp.fromDate(contract.contractEndYearMonth),
      'useYearStartMonth': contract.useYearStartMonth,
      'annualPoint': contract.annualPoint,
      ...FirestoreWriteMetadata.forCreate(),
    };
  }
}
