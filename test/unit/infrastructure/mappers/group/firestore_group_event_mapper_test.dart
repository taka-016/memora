import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_event_mapper.dart';
import 'package:memora/domain/entities/group/group_event.dart';

@GenerateMocks([QueryDocumentSnapshot])
void main() {
  group('FirestoreGroupEventMapper', () {
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
