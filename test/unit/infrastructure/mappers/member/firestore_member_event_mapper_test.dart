import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_event_mapper.dart';
import 'package:memora/domain/entities/member/member_event.dart';

@GenerateMocks([QueryDocumentSnapshot])
void main() {
  group('FirestoreMemberEventMapper', () {
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
