import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_limited_point_mapper.dart';

import '../../../../helpers/fake_document_snapshot.dart';

void main() {
  group('FirestoreDvcLimitedPointMapper', () {
    test('FirestoreドキュメントからDtoへ変換できる', () {
      final doc = FakeDocumentSnapshot(
        docId: 'limited001',
        data: {
          'groupId': 'group001',
          'startYearMonth': Timestamp.fromDate(DateTime(2025, 7)),
          'endYearMonth': Timestamp.fromDate(DateTime(2025, 12)),
          'point': 30,
        },
      );

      final dto = FirestoreDvcLimitedPointMapper.fromFirestore(doc);

      expect(dto.id, 'limited001');
      expect(dto.groupId, 'group001');
      expect(dto.startYearMonth, DateTime(2025, 7));
      expect(dto.endYearMonth, DateTime(2025, 12));
      expect(dto.point, 30);
    });

    test('Firestore欠損値はデフォルトで補完する', () {
      final doc = FakeDocumentSnapshot(docId: 'limited002', data: {});

      final dto = FirestoreDvcLimitedPointMapper.fromFirestore(doc);

      expect(dto.id, 'limited002');
      expect(dto.groupId, '');
      expect(dto.point, 0);
      expect(dto.startYearMonth, DateTime.fromMillisecondsSinceEpoch(0));
      expect(dto.endYearMonth, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('エンティティをFirestoreマップへ変換できる', () {
      final point = DvcLimitedPoint(
        id: 'limited003',
        groupId: 'group003',
        startYearMonth: DateTime(2025, 7),
        endYearMonth: DateTime(2025, 12),
        point: 30,
      );

      final map = FirestoreDvcLimitedPointMapper.toFirestore(point);

      expect(map['groupId'], 'group003');
      expect(map['startYearMonth'], isA<Timestamp>());
      expect(map['endYearMonth'], isA<Timestamp>());
      expect(map['point'], 30);
      expect(map['createdAt'], isA<FieldValue>());
    });
  });
}
