import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_point_usage_mapper.dart';

import 'firestore_dvc_point_usage_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('FirestoreDvcPointUsageMapper', () {
    test('FirestoreドキュメントからDvcPointUsageDtoへ変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('usage001');
      when(doc.data()).thenReturn({
        'groupId': 'group001',
        'usageYearMonth': Timestamp.fromDate(DateTime(2025, 10)),
        'usedPoint': 60.4,
        'memo': 'ホテル',
      });

      final result = FirestoreDvcPointUsageMapper.fromFirestore(doc);

      expect(result.id, 'usage001');
      expect(result.groupId, 'group001');
      expect(result.usageYearMonth, DateTime(2025, 10));
      expect(result.usedPoint, 60);
      expect(result.memo, 'ホテル');
    });

    test('Firestoreの欠損値をデフォルトで変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('usage002');
      when(doc.data()).thenReturn({});

      final result = FirestoreDvcPointUsageMapper.fromFirestore(doc);

      expect(result.id, 'usage002');
      expect(result.groupId, '');
      expect(result.usageYearMonth, DateTime.fromMillisecondsSinceEpoch(0));
      expect(result.usedPoint, 0);
      expect(result.memo, isNull);
    });

    test('エンティティをFirestoreマップへ変換できる', () {
      final usage = DvcPointUsage(
        id: 'usage001',
        groupId: 'group001',
        usageYearMonth: DateTime(2025, 10),
        usedPoint: 60,
        memo: 'ホテル',
      );

      final map = FirestoreDvcPointUsageMapper.toFirestore(usage);

      expect(map['groupId'], 'group001');
      expect(map['usageYearMonth'], isA<Timestamp>());
      expect(map['usedPoint'], 60);
      expect(map['memo'], 'ホテル');
      expect(map['createdAt'], isA<FieldValue>());
    });
  });
}
