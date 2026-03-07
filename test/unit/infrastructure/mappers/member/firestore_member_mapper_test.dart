import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_mapper.dart';
import 'package:memora/domain/entities/member/member.dart';

import 'firestore_member_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('FirestoreMemberMapper', () {
    test('FirestoreドキュメントからMemberDtoへ変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('member001');
      when(doc.data()).thenReturn({
        'accountId': 'account001',
        'ownerId': 'owner001',
        'displayName': '山田太郎',
        'birthday': Timestamp.fromDate(DateTime(2001, 2, 3)),
        'email': 'taro@example.com',
      });

      final result = FirestoreMemberMapper.fromFirestore(doc);

      expect(result.id, 'member001');
      expect(result.accountId, 'account001');
      expect(result.ownerId, 'owner001');
      expect(result.displayName, '山田太郎');
      expect(result.birthday, DateTime(2001, 2, 3));
      expect(result.email, 'taro@example.com');
    });

    test('Firestoreの欠損値をデフォルトで変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('member002');
      when(doc.data()).thenReturn({});

      final result = FirestoreMemberMapper.fromFirestore(doc);

      expect(result.id, 'member002');
      expect(result.displayName, '');
      expect(result.birthday, isNull);
      expect(result.accountId, isNull);
      expect(result.ownerId, isNull);
    });

    test('MemberからFirestoreのMapへ変換できる', () {
      final member = Member(
        id: 'member001',
        accountId: 'account001',
        ownerId: 'admin001',
        hiraganaFirstName: 'たろう',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '太郎',
        kanjiLastName: '山田',
        firstName: 'Taro',
        lastName: 'Yamada',
        displayName: 'たろちゃん',
        type: '一般',
        birthday: DateTime(2000, 1, 1),
        gender: 'male',
        email: 'taro@example.com',
      );

      final data = FirestoreMemberMapper.toFirestore(member);

      expect(data['accountId'], 'account001');
      expect(data['ownerId'], 'admin001');
      expect(data['hiraganaFirstName'], 'たろう');
      expect(data['hiraganaLastName'], 'やまだ');
      expect(data['kanjiFirstName'], '太郎');
      expect(data['kanjiLastName'], '山田');
      expect(data['firstName'], 'Taro');
      expect(data['lastName'], 'Yamada');
      expect(data['displayName'], 'たろちゃん');
      expect(data['type'], '一般');
      expect(data['birthday'], isA<Timestamp>());
      expect(data['gender'], 'male');
      expect(data['email'], 'taro@example.com');
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('nullフィールドを含むMemberからFirestoreのMapへ変換できる', () {
      final member = Member(id: 'member003', displayName: 'たろちゃん');

      final data = FirestoreMemberMapper.toFirestore(member);

      expect(data['accountId'], null);
      expect(data['ownerId'], null);
      expect(data['hiraganaFirstName'], null);
      expect(data['hiraganaLastName'], null);
      expect(data['kanjiFirstName'], null);
      expect(data['kanjiLastName'], null);
      expect(data['firstName'], null);
      expect(data['lastName'], null);
      expect(data['displayName'], 'たろちゃん');
      expect(data['type'], null);
      expect(data['birthday'], null);
      expect(data['gender'], null);
      expect(data['email'], null);
      expect(data['phoneNumber'], null);
      expect(data['passportNumber'], null);
      expect(data['passportExpiration'], null);
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
