import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/firestore_member_mapper.dart';
import 'package:memora/domain/entities/member.dart';
import '../repositories/firestore_member_repository_test.mocks.dart';

void main() {
  group('FirestoreMemberMapper', () {
    test('FirestoreのDocumentSnapshotからMemberへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('member001');
      when(mockDoc.data()).thenReturn({
        'accountId': 'account001',
        'administratorId': 'admin001',
        'hiraganaFirstName': 'たろう',
        'hiraganaLastName': 'やまだ',
        'kanjiFirstName': '太郎',
        'kanjiLastName': '山田',
        'firstName': 'Taro',
        'lastName': 'Yamada',
        'displayName': 'たろちゃん',
        'type': '一般',
        'birthday': Timestamp.fromDate(DateTime(2000, 1, 1)),
        'gender': 'male',
        'email': 'taro@example.com',
        'phoneNumber': '090-1234-5678',
        'passportNumber': 'A1234567',
        'passportExpiration': '2030-01-01',
        'anaMileageNumber': 'ANA123456',
        'jalMileageNumber': 'JAL123456',
      });

      final member = FirestoreMemberMapper.fromFirestore(mockDoc);

      expect(member.id, 'member001');
      expect(member.accountId, 'account001');
      expect(member.administratorId, 'admin001');
      expect(member.hiraganaFirstName, 'たろう');
      expect(member.hiraganaLastName, 'やまだ');
      expect(member.kanjiFirstName, '太郎');
      expect(member.kanjiLastName, '山田');
      expect(member.firstName, 'Taro');
      expect(member.lastName, 'Yamada');
      expect(member.displayName, 'たろちゃん');
      expect(member.type, '一般');
      expect(member.birthday, DateTime(2000, 1, 1));
      expect(member.gender, 'male');
      expect(member.email, 'taro@example.com');
      expect(member.phoneNumber, '090-1234-5678');
      expect(member.passportNumber, 'A1234567');
      expect(member.passportExpiration, '2030-01-01');
      expect(member.anaMileageNumber, 'ANA123456');
      expect(member.jalMileageNumber, 'JAL123456');
    });

    test('nullableなフィールドがnullの場合でも変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('member002');
      when(mockDoc.data()).thenReturn({'displayName': 'たろちゃん'});

      final member = FirestoreMemberMapper.fromFirestore(mockDoc);

      expect(member.id, 'member002');
      expect(member.accountId, null);
      expect(member.administratorId, null);
      expect(member.hiraganaFirstName, null);
      expect(member.hiraganaLastName, null);
      expect(member.kanjiFirstName, null);
      expect(member.kanjiLastName, null);
      expect(member.firstName, null);
      expect(member.lastName, null);
      expect(member.displayName, 'たろちゃん');
      expect(member.type, null);
      expect(member.birthday, null);
      expect(member.gender, null);
      expect(member.email, null);
      expect(member.phoneNumber, null);
      expect(member.passportNumber, null);
      expect(member.passportExpiration, null);
      expect(member.anaMileageNumber, null);
      expect(member.jalMileageNumber, null);
    });

    test('MemberからFirestoreのMapへ変換できる', () {
      final member = Member(
        id: 'member001',
        accountId: 'account001',
        administratorId: 'admin001',
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
      expect(data['administratorId'], 'admin001');
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
      expect(data['administratorId'], null);
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
      expect(data['anaMileageNumber'], null);
      expect(data['jalMileageNumber'], null);
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
