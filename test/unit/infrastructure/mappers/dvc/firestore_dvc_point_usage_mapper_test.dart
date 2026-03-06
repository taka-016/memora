import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_point_usage_mapper.dart';

import '../../../../helpers/fake_document_snapshot.dart';

void main() {
  group('FirestoreDvcPointUsageMapper', () {
    test('FirestoreドキュメントからDtoへ変換できる', () {
      final doc = FakeDocumentSnapshot(
        docId: 'usage001',
        data: {
          'groupId': 'group001',
          'usageYearMonth': Timestamp.fromDate(DateTime(2025, 10)),
          'usedPoint': 60,
        },
      );

      final dto = FirestoreDvcPointUsageMapper.fromFirestore(doc);

      expect(dto.id, 'usage001');
      expect(dto.groupId, 'group001');
      expect(dto.usageYearMonth, DateTime(2025, 10));
      expect(dto.usedPoint, 60);
    });

    test('Firestore欠損値はデフォルトで補完する', () {
      final doc = FakeDocumentSnapshot(docId: 'usage002', data: {});

      final dto = FirestoreDvcPointUsageMapper.fromFirestore(doc);

      expect(dto.id, 'usage002');
      expect(dto.groupId, '');
      expect(dto.usedPoint, 0);
      expect(dto.usageYearMonth, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('エンティティをFirestoreマップへ変換できる', () {
      final usage = DvcPointUsage(
        id: 'usage003',
        groupId: 'group003',
        usageYearMonth: DateTime(2025, 10),
        usedPoint: 60,
      );

      final map = FirestoreDvcPointUsageMapper.toFirestore(usage);

      expect(map['groupId'], 'group003');
      expect(map['usageYearMonth'], isA<Timestamp>());
      expect(map['usedPoint'], 60);
      expect(map['createdAt'], isA<FieldValue>());
    });
  });
}
