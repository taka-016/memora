import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/group/group_event.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_event_mapper.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'firestore_group_event_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('FirestoreGroupEventMapper', () {
    test('FirestoreドキュメントからGroupEventDtoへ変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('event001');
      when(
        doc.data(),
      ).thenReturn({'groupId': 'group001', 'year': 2025, 'memo': '準備あり'});

      final result = FirestoreGroupEventMapper.fromFirestore(doc);

      expect(result.id, 'event001');
      expect(result.groupId, 'group001');
      expect(result.year, 2025);
      expect(result.memo, '準備あり');
    });

    test('Firestoreの欠損値をデフォルトで変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('event002');
      when(doc.data()).thenReturn({});

      final result = FirestoreGroupEventMapper.fromFirestore(doc);

      expect(result.id, 'event002');
      expect(result.groupId, '');
      expect(result.year, 0);
      expect(result.memo, '');
    });

    test('GroupEventを新規作成用FirestoreのMapへ変換できる', () {
      const groupEvent = GroupEvent(
        id: 'groupevent001',
        groupId: 'group001',
        year: 2025,
        memo: 'テストメモ',
      );

      final data = FirestoreGroupEventMapper.toCreateFirestore(groupEvent);

      expect(data['groupId'], 'group001');
      expect(data['year'], 2025);
      expect(data['memo'], 'テストメモ');
      expect(data['createdAt'], isA<FieldValue>());
      expect(data['updatedAt'], isA<FieldValue>());
    });

    test('GroupEventを更新用FirestoreのMapへ変換できる', () {
      const groupEvent = GroupEvent(
        id: 'groupevent001',
        groupId: 'group001',
        year: 2025,
        memo: '更新後メモ',
      );

      final data = FirestoreGroupEventMapper.toUpdateFirestore(groupEvent);

      expect(data['groupId'], 'group001');
      expect(data['year'], 2025);
      expect(data['memo'], '更新後メモ');
      expect(data.containsKey('createdAt'), isFalse);
      expect(data['updatedAt'], isA<FieldValue>());
    });
  });
}
