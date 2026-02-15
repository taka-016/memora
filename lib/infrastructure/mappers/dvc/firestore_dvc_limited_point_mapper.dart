import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';

class FirestoreDvcLimitedPointMapper {
  static Map<String, dynamic> toFirestore(DvcLimitedPoint limitedPoint) {
    return {
      'groupId': limitedPoint.groupId,
      'startYearMonth': Timestamp.fromDate(limitedPoint.startYearMonth),
      'endYearMonth': Timestamp.fromDate(limitedPoint.endYearMonth),
      'point': limitedPoint.point,
      'memo': limitedPoint.memo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
