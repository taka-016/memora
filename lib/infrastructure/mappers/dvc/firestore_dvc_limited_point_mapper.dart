import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/infrastructure/mappers/firestore_mapper_value_parser.dart';

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
          FirestoreMapperValueParser.asDateTime(data['startYearMonth']) ??
          _defaultDate,
      endYearMonth:
          FirestoreMapperValueParser.asDateTime(data['endYearMonth']) ??
          _defaultDate,
      point: FirestoreMapperValueParser.asInt(data['point']),
      memo: data['memo']?.toString(),
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
}
