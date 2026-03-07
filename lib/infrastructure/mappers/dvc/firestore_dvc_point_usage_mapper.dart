import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/infrastructure/mappers/firestore_mapper_value_parser.dart';

class FirestoreDvcPointUsageMapper {
  static final _defaultDate = DateTime.fromMillisecondsSinceEpoch(0);

  static DvcPointUsageDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DvcPointUsageDto(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      usageYearMonth:
          FirestoreMapperValueParser.asDateTime(data['usageYearMonth']) ??
          _defaultDate,
      usedPoint: FirestoreMapperValueParser.asInt(data['usedPoint']),
      memo: data['memo'] as String?,
    );
  }

  static Map<String, dynamic> toFirestore(DvcPointUsage pointUsage) {
    return {
      'groupId': pointUsage.groupId,
      'usageYearMonth': Timestamp.fromDate(pointUsage.usageYearMonth),
      'usedPoint': pointUsage.usedPoint,
      'memo': pointUsage.memo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
