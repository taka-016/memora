import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/firestore_member_event_mapper.dart';
import 'package:memora/domain/entities/member_event.dart';
import '../repositories/firestore_member_event_repository_test.mocks.dart';

void main() {
  group('FirestoreMemberEventMapper', () {
    test('FirestoreのDocumentSnapshotからMemberEventへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('memberevent001');
      when(mockDoc.data()).thenReturn({
        'memberId': 'member001',
        'type': 'birthday',
        'name': 'テストイベント',
        'startDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 6, 2)),
        'memo': 'テストメモ',
      });

      final memberEvent = FirestoreMemberEventMapper.fromFirestore(mockDoc);

      expect(memberEvent.id, 'memberevent001');
      expect(memberEvent.memberId, 'member001');
      expect(memberEvent.type, 'birthday');
      expect(memberEvent.name, 'テストイベント');
      expect(memberEvent.startDate, DateTime(2025, 6, 1));
      expect(memberEvent.endDate, DateTime(2025, 6, 2));
      expect(memberEvent.memo, 'テストメモ');
    });

    test('nullableなフィールドがnullの場合でも変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('memberevent002');
      when(mockDoc.data()).thenReturn({
        'memberId': 'member001',
        'type': 'birthday',
        'startDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 6, 2)),
      });

      final memberEvent = FirestoreMemberEventMapper.fromFirestore(mockDoc);

      expect(memberEvent.id, 'memberevent002');
      expect(memberEvent.memberId, 'member001');
      expect(memberEvent.type, 'birthday');
      expect(memberEvent.name, null);
      expect(memberEvent.memo, null);
    });

    test('MemberEventからFirestoreのMapへ変換できる', () {
      final memberEvent = MemberEvent(
        id: 'memberevent001',
        memberId: 'member001',
        type: 'birthday',
        name: 'テストイベント',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 2),
        memo: 'テストメモ',
      );

      final data = FirestoreMemberEventMapper.toFirestore(memberEvent);

      expect(data['memberId'], 'member001');
      expect(data['type'], 'birthday');
      expect(data['name'], 'テストイベント');
      expect(data['startDate'], isA<Timestamp>());
      expect(data['endDate'], isA<Timestamp>());
      expect(data['memo'], 'テストメモ');
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}