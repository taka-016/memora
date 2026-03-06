import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_mapper.dart';

import '../../../../helpers/fake_document_snapshot.dart';

void main() {
  group('FirestoreMemberMapper', () {
    test('FirestoreドキュメントからMemberDtoへ変換できる', () {
      final doc = FakeDocumentSnapshot(
        docId: 'member001',
        data: {
          'accountId': 'account001',
          'ownerId': 'owner001',
          'displayName': '山田太郎',
          'birthday': Timestamp.fromDate(DateTime(2000, 1, 1)),
        },
      );

      final dto = FirestoreMemberMapper.fromFirestore(doc);

      expect(dto.id, 'member001');
      expect(dto.accountId, 'account001');
      expect(dto.ownerId, 'owner001');
      expect(dto.displayName, '山田太郎');
      expect(dto.birthday, DateTime(2000, 1, 1));
    });

    test('displayNameがない場合は空文字になる', () {
      final doc = FakeDocumentSnapshot(docId: 'member002', data: {});

      final dto = FirestoreMemberMapper.fromFirestore(doc);

      expect(dto.id, 'member002');
      expect(dto.displayName, '');
    });

    test('MemberをFirestoreのMapへ変換できる', () {
      final member = Member(
        id: 'member003',
        accountId: 'account003',
        ownerId: 'owner003',
        displayName: 'たろちゃん',
        birthday: DateTime(2000, 1, 1),
      );

      final data = FirestoreMemberMapper.toFirestore(member);

      expect(data['accountId'], 'account003');
      expect(data['ownerId'], 'owner003');
      expect(data['displayName'], 'たろちゃん');
      expect(data['birthday'], isA<Timestamp>());
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
