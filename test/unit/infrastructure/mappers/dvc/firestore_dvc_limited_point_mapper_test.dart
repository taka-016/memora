import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_limited_point_mapper.dart';

import 'firestore_dvc_limited_point_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('FirestoreDvcLimitedPointMapper', () {
    test('FirestoreドキュメントからDvcLimitedPointDtoへ変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('limited001');
      when(doc.data()).thenReturn({
        'groupId': 'group001',
        'startYearMonth': Timestamp.fromDate(DateTime(2025, 7)),
        'endYearMonth': Timestamp.fromDate(DateTime(2025, 12)),
        'point': 30.7,
        'memo': '追加分',
      });

      final result = FirestoreDvcLimitedPointMapper.fromFirestore(doc);

      expect(result.id, 'limited001');
      expect(result.groupId, 'group001');
      expect(result.startYearMonth, DateTime(2025, 7));
      expect(result.endYearMonth, DateTime(2025, 12));
      expect(result.point, 30);
      expect(result.memo, '追加分');
    });

    test('memoが文字列以外の場合はnullへ変換される', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('limited003');
      when(doc.data()).thenReturn({
        'memo': {'unexpected': 'value'},
      });

      final result = FirestoreDvcLimitedPointMapper.fromFirestore(doc);

      expect(result.memo, isNull);
    });

    test('Firestoreの欠損値をデフォルトで変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('limited002');
      when(doc.data()).thenReturn({});

      final result = FirestoreDvcLimitedPointMapper.fromFirestore(doc);

      expect(result.id, 'limited002');
      expect(result.groupId, '');
      expect(result.startYearMonth, DateTime.fromMillisecondsSinceEpoch(0));
      expect(result.endYearMonth, DateTime.fromMillisecondsSinceEpoch(0));
      expect(result.point, 0);
      expect(result.memo, isNull);
    });

    test('エンティティをFirestoreマップへ変換できる', () {
      final point = DvcLimitedPoint(
        id: 'limited001',
        groupId: 'group001',
        startYearMonth: DateTime(2025, 7),
        endYearMonth: DateTime(2025, 12),
        point: 30,
        memo: '追加分',
      );

      final map = FirestoreDvcLimitedPointMapper.toCreateFirestore(point);

      expect(map['groupId'], 'group001');
      expect(map['startYearMonth'], isA<Timestamp>());
      expect(map['endYearMonth'], isA<Timestamp>());
      expect(map['point'], 30);
      expect(map['memo'], '追加分');
      expect(map['createdAt'], isA<FieldValue>());
      expect(map['updatedAt'], isA<FieldValue>());
    });
  });
}
