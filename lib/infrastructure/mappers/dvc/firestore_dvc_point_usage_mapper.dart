import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';

class FirestoreDvcPointUsageMapper {
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
