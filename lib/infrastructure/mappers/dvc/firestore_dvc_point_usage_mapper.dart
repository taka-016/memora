import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';

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
          (data['usageYearMonth'] as Timestamp?)?.toDate() ?? _defaultDate,
      usedPoint: _asInt(data['usedPoint']),
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

  static int _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
