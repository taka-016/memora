import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/firestore_group_event_mapper.dart';
import 'package:memora/domain/entities/group_event.dart';

import 'firestore_group_event_mapper_test.mocks.dart';

@GenerateMocks([QueryDocumentSnapshot])
void main() {
  group('FirestoreGroupEventMapper', () {
    test('FirestoreのDocumentSnapshotからGroupEventへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('groupevent001');
      when(mockDoc.data()).thenReturn({
        'groupId': 'group001',
        'type': 'meeting',
        'name': 'テストイベント',
        'startDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 6, 2)),
        'memo': 'テストメモ',
      });

      final groupEvent = FirestoreGroupEventMapper.fromFirestore(mockDoc);

      expect(groupEvent.groupId, 'group001');
      expect(groupEvent.type, 'meeting');
      expect(groupEvent.name, 'テストイベント');
      expect(groupEvent.startDate, DateTime(2025, 6, 1));
      expect(groupEvent.endDate, DateTime(2025, 6, 2));
      expect(groupEvent.memo, 'テストメモ');
    });

    test('nullableなフィールドがnullの場合でも変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('groupevent002');
      when(mockDoc.data()).thenReturn({
        'groupId': 'group001',
        'type': 'meeting',
        'startDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 6, 2)),
      });

      final groupEvent = FirestoreGroupEventMapper.fromFirestore(mockDoc);

      expect(groupEvent.groupId, 'group001');
      expect(groupEvent.type, 'meeting');
      expect(groupEvent.name, null);
      expect(groupEvent.memo, null);
    });

    test('Firestoreのデータがnullの場合はデフォルト値に変換される', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('groupevent003');
      when(mockDoc.data()).thenReturn({});
      final before = DateTime.now();

      final groupEvent = FirestoreGroupEventMapper.fromFirestore(mockDoc);
      final after = DateTime.now();

      expect(groupEvent.groupId, '');
      expect(groupEvent.type, '');
      expect(groupEvent.name, isNull);
      expect(groupEvent.memo, isNull);
      expect(
        groupEvent.startDate.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(
        groupEvent.startDate.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        groupEvent.endDate.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        groupEvent.endDate.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('GroupEventからFirestoreのMapへ変換できる', () {
      final groupEvent = GroupEvent(
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
