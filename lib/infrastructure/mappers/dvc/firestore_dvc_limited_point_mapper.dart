import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';

class FirestoreDvcLimitedPointMapper {
  static final _defaultDate = DateTime.fromMillisecondsSinceEpoch(0);

  static DvcLimitedPointDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DvcLimitedPointDto(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      startYearMonth:
          (data['startYearMonth'] as Timestamp?)?.toDate() ?? _defaultDate,
      endYearMonth:
          (data['endYearMonth'] as Timestamp?)?.toDate() ?? _defaultDate,
      point: _asInt(data['point']),
      memo: data['memo'] as String?,
    );
  }

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

  static int _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
