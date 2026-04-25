import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member/member_event.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_event_mapper.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'firestore_member_event_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('FirestoreMemberEventMapper', () {
    test('FirestoreドキュメントからMemberEventDtoへ変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('event001');
      when(
        doc.data(),
      ).thenReturn({'memberId': 'member001', 'year': 2026, 'memo': '入学式'});

      final result = FirestoreMemberEventMapper.fromFirestore(doc);

      expect(result.id, 'event001');
      expect(result.memberId, 'member001');
      expect(result.year, 2026);
      expect(result.memo, '入学式');
    });

    test('Firestoreの欠損値をER図項目のデフォルトで変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('event002');
      when(doc.data()).thenReturn({});

      final result = FirestoreMemberEventMapper.fromFirestore(doc);

      expect(result.id, 'event002');
      expect(result.memberId, '');
      expect(result.year, 0);
      expect(result.memo, '');
    });

    test('MemberEventを新規作成用FirestoreのMapへ変換できる', () {
      const memberEvent = MemberEvent(
        id: '',
        memberId: 'member001',
        year: 2026,
        memo: '入学式',
      );

      final data = FirestoreMemberEventMapper.toCreateFirestore(memberEvent);

      expect(data['memberId'], 'member001');
      expect(data['year'], 2026);
      expect(data['memo'], '入学式');
      expect(data['createdAt'], isA<FieldValue>());
      expect(data['updatedAt'], isA<FieldValue>());
      expect(data, isNot(contains('type')));
      expect(data, isNot(contains('name')));
      expect(data, isNot(contains('startDate')));
      expect(data, isNot(contains('endDate')));
    });

    test('MemberEventを更新用FirestoreのMapへ変換できる', () {
      const memberEvent = MemberEvent(
        id: 'memberevent001',
        memberId: 'member001',
        year: 2026,
        memo: '卒業式',
      );

      final data = FirestoreMemberEventMapper.toUpdateFirestore(memberEvent);

      expect(data['memberId'], 'member001');
      expect(data['year'], 2026);
      expect(data['memo'], '卒業式');
      expect(data['updatedAt'], isA<FieldValue>());
      expect(data, isNot(contains('createdAt')));
    });
  });
}
