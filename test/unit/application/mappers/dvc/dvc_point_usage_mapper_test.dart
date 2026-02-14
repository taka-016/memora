import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_point_usage_mapper.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'dvc_point_usage_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('DvcPointUsageMapper', () {
    test('FirestoreドキュメントからDtoへ変換できる', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('usage001');
      when(mockDoc.data()).thenReturn({
        'groupId': 'group001',
        'usageYearMonth': Timestamp.fromDate(DateTime(2025, 10)),
        'usedPoint': 60,
        'memo': 'ホテル',
      });

      final dto = DvcPointUsageMapper.fromFirestore(mockDoc);

      expect(dto.id, 'usage001');
      expect(dto.groupId, 'group001');
      expect(dto.usageYearMonth, DateTime(2025, 10));
      expect(dto.usedPoint, 60);
      expect(dto.memo, 'ホテル');
    });

    test('Dtoからエンティティへ変換できる', () {
      final dto = DvcPointUsageDto(
        id: 'usage001',
        groupId: 'group001',
        usageYearMonth: DateTime(2025, 10),
        usedPoint: 60,
        memo: 'ホテル',
      );

      final entity = DvcPointUsageMapper.toEntity(dto);

      expect(
        entity,
        DvcPointUsage(
          id: 'usage001',
          groupId: 'group001',
          usageYearMonth: DateTime(2025, 10),
          usedPoint: 60,
          memo: 'ホテル',
        ),
      );
    });

    test('Firestoreの欠損値はデフォルトで補完される', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('usage001');
      when(mockDoc.data()).thenReturn({});

      final dto = DvcPointUsageMapper.fromFirestore(mockDoc);

      expect(dto.groupId, '');
      expect(dto.usageYearMonth, DateTime.fromMillisecondsSinceEpoch(0));
      expect(dto.usedPoint, 0);
      expect(dto.memo, isNull);
    });
  });
}
