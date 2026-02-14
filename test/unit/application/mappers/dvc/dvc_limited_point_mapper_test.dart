import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_limited_point_mapper.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'dvc_limited_point_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('DvcLimitedPointMapper', () {
    test('FirestoreドキュメントからDtoへ変換できる', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('limited001');
      when(mockDoc.data()).thenReturn({
        'groupId': 'group001',
        'startYearMonth': Timestamp.fromDate(DateTime(2025, 7)),
        'endYearMonth': Timestamp.fromDate(DateTime(2025, 12)),
        'point': 30,
        'memo': '追加分',
      });

      final dto = DvcLimitedPointMapper.fromFirestore(mockDoc);

      expect(dto.id, 'limited001');
      expect(dto.groupId, 'group001');
      expect(dto.startYearMonth, DateTime(2025, 7));
      expect(dto.endYearMonth, DateTime(2025, 12));
      expect(dto.point, 30);
      expect(dto.memo, '追加分');
    });

    test('Dtoからエンティティへ変換できる', () {
      final dto = DvcLimitedPointDto(
        id: 'limited001',
        groupId: 'group001',
        startYearMonth: DateTime(2025, 7),
        endYearMonth: DateTime(2025, 12),
        point: 30,
        memo: '追加分',
      );

      final entity = DvcLimitedPointMapper.toEntity(dto);

      expect(
        entity,
        DvcLimitedPoint(
          id: 'limited001',
          groupId: 'group001',
          startYearMonth: DateTime(2025, 7),
          endYearMonth: DateTime(2025, 12),
          point: 30,
          memo: '追加分',
        ),
      );
    });

    test('Firestoreの欠損値はデフォルトで補完される', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('limited001');
      when(mockDoc.data()).thenReturn({});

      final dto = DvcLimitedPointMapper.fromFirestore(mockDoc);

      expect(dto.groupId, '');
      expect(dto.startYearMonth, DateTime.fromMillisecondsSinceEpoch(0));
      expect(dto.endYearMonth, DateTime.fromMillisecondsSinceEpoch(0));
      expect(dto.point, 0);
      expect(dto.memo, isNull);
    });
  });
}
