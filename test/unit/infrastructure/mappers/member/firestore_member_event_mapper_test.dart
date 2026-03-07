import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_event_mapper.dart';
import 'package:memora/domain/entities/member/member_event.dart';

import 'firestore_member_event_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('FirestoreMemberEventMapper', () {
    test('FirestoreドキュメントからMemberEventDtoへ変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('event001');
      when(doc.data()).thenReturn({
        'memberId': 'member001',
        'type': 'birthday',
        'name': '誕生日',
        'startDate': Timestamp.fromDate(DateTime(2025, 3, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 3, 2)),
        'memo': 'ケーキ',
      });

      final result = FirestoreMemberEventMapper.fromFirestore(doc);

      expect(result.id, 'event001');
      expect(result.memberId, 'member001');
      expect(result.type, 'birthday');
      expect(result.name, '誕生日');
      expect(result.startDate, DateTime(2025, 3, 1));
      expect(result.endDate, DateTime(2025, 3, 2));
      expect(result.memo, 'ケーキ');
    });

    test('Firestoreの欠損値をデフォルトで変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('event002');
      when(doc.data()).thenReturn({});

      final result = FirestoreMemberEventMapper.fromFirestore(doc);

      expect(result.id, 'event002');
      expect(result.memberId, '');
      expect(result.type, '');
      expect(result.startDate, DateTime.fromMillisecondsSinceEpoch(0));
      expect(result.endDate, DateTime.fromMillisecondsSinceEpoch(0));
      expect(result.name, isNull);
      expect(result.memo, isNull);
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

    test('nullableなフィールドがnullでもFirestoreのMapへ変換できる', () {
      final memberEvent = MemberEvent(
        id: 'memberevent004',
        memberId: 'member002',
        type: 'anniversary',
        startDate: DateTime(2025, 8, 1),
        endDate: DateTime(2025, 8, 2),
      );

      final data = FirestoreMemberEventMapper.toFirestore(memberEvent);

      expect(data['memberId'], 'member002');
      expect(data['type'], 'anniversary');
      expect(data['name'], isNull);
      expect(data['startDate'], isA<Timestamp>());
      expect(data['endDate'], isA<Timestamp>());
      expect(data['memo'], isNull);
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
