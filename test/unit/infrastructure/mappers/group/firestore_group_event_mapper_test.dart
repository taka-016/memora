import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_event_mapper.dart';
import 'package:memora/domain/entities/group/group_event.dart';

import 'firestore_group_event_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('FirestoreGroupEventMapper', () {
    test('FirestoreドキュメントからGroupEventDtoへ変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('event001');
      when(doc.data()).thenReturn({
        'groupId': 'group001',
        'type': 'birthday',
        'name': '誕生日',
        'startDate': Timestamp.fromDate(DateTime(2025, 1, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 1, 2)),
        'memo': '準備あり',
      });

      final result = FirestoreGroupEventMapper.fromFirestore(doc);

      expect(result.id, 'event001');
      expect(result.groupId, 'group001');
      expect(result.type, 'birthday');
      expect(result.name, '誕生日');
      expect(result.startDate, DateTime(2025, 1, 1));
      expect(result.endDate, DateTime(2025, 1, 2));
      expect(result.memo, '準備あり');
    });

    test('Firestoreの欠損値をデフォルトで変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('event002');
      when(doc.data()).thenReturn({});

      final result = FirestoreGroupEventMapper.fromFirestore(doc);

      expect(result.id, 'event002');
      expect(result.groupId, '');
      expect(result.type, '');
      expect(result.startDate, DateTime.fromMillisecondsSinceEpoch(0));
      expect(result.endDate, DateTime.fromMillisecondsSinceEpoch(0));
      expect(result.name, isNull);
      expect(result.memo, isNull);
    });

    test('GroupEventからFirestoreのMapへ変換できる', () {
      final groupEvent = GroupEvent(
        id: 'groupevent001',
        groupId: 'group001',
        type: 'meeting',
        name: 'テストイベント',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 2),
        memo: 'テストメモ',
      );

      final data = FirestoreGroupEventMapper.toFirestore(groupEvent);

      expect(data['groupId'], 'group001');
      expect(data['type'], 'meeting');
      expect(data['name'], 'テストイベント');
      expect(data['startDate'], isA<Timestamp>());
      expect(data['endDate'], isA<Timestamp>());
      expect(data['memo'], 'テストメモ');
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('nullableなフィールドがnullでもFirestoreのMapへ変換できる', () {
      final groupEvent = GroupEvent(
        id: 'groupevent004',
        groupId: 'group002',
        type: 'reminder',
        startDate: DateTime(2025, 7, 10),
        endDate: DateTime(2025, 7, 11),
      );

      final data = FirestoreGroupEventMapper.toFirestore(groupEvent);

      expect(data['groupId'], 'group002');
      expect(data['type'], 'reminder');
      expect(data['name'], isNull);
      expect(data['startDate'], isA<Timestamp>());
      expect(data['endDate'], isA<Timestamp>());
      expect(data['memo'], isNull);
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
