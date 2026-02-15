import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_limited_point_mapper.dart';

void main() {
  group('FirestoreDvcLimitedPointMapper', () {
    test('エンティティをFirestoreマップへ変換できる', () {
      final point = DvcLimitedPoint(
        id: 'limited001',
        groupId: 'group001',
        startYearMonth: DateTime(2025, 7),
        endYearMonth: DateTime(2025, 12),
        point: 30,
        memo: '追加分',
      );

      final map = FirestoreDvcLimitedPointMapper.toFirestore(point);

      expect(map['groupId'], 'group001');
      expect(map['startYearMonth'], isA<Timestamp>());
      expect(map['endYearMonth'], isA<Timestamp>());
      expect(map['point'], 30);
      expect(map['memo'], '追加分');
      expect(map['createdAt'], isA<FieldValue>());
    });
  });
}
