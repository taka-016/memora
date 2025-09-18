import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/member_mapper.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'member_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
MockDocumentSnapshot<Map<String, dynamic>> _createDocument({
  String id = 'member001',
  Map<String, dynamic>? data,
}) {
  final doc = MockDocumentSnapshot<Map<String, dynamic>>();
  when(doc.id).thenReturn(id);
  when(doc.data()).thenReturn(data);
  return doc;
}

Member _createMember({
  String id = 'member-1',
  String displayName = 'タロちゃん',
  String? accountId,
  String? ownerId,
  String? hiraganaFirstName,
  String? hiraganaLastName,
  String? kanjiFirstName,
  String? kanjiLastName,
  String? firstName,
  String? lastName,
  String? type,
  DateTime? birthday,
  String? gender,
  String? email,
  String? phoneNumber,
  String? passportNumber,
  String? passportExpiration,
}) {
  return Member(
    id: id,
    accountId: accountId,
    ownerId: ownerId,
    hiraganaFirstName: hiraganaFirstName,
    hiraganaLastName: hiraganaLastName,
    kanjiFirstName: kanjiFirstName,
    kanjiLastName: kanjiLastName,
    firstName: firstName,
    lastName: lastName,
    displayName: displayName,
    type: type,
    birthday: birthday,
    gender: gender,
    email: email,
    phoneNumber: phoneNumber,
    passportNumber: passportNumber,
    passportExpiration: passportExpiration,
  );
}

MemberDto _createMemberDto({
  String id = 'member-1',
  String displayName = 'タロちゃん',
  String? accountId,
  String? ownerId,
  String? hiraganaFirstName,
  String? hiraganaLastName,
  String? kanjiFirstName,
  String? kanjiLastName,
  String? firstName,
  String? lastName,
  String? type,
  DateTime? birthday,
  String? gender,
  String? email,
  String? phoneNumber,
  String? passportNumber,
  String? passportExpiration,
}) {
  return MemberDto(
    id: id,
    accountId: accountId,
    ownerId: ownerId,
    hiraganaFirstName: hiraganaFirstName,
    hiraganaLastName: hiraganaLastName,
    kanjiFirstName: kanjiFirstName,
    kanjiLastName: kanjiLastName,
    firstName: firstName,
    lastName: lastName,
    displayName: displayName,
    type: type,
    birthday: birthday,
    gender: gender,
    email: email,
    phoneNumber: phoneNumber,
    passportNumber: passportNumber,
    passportExpiration: passportExpiration,
  );
}

void main() {
  group('MemberMapper', () {
    group('fromFirestore', () {
      test('FirestoreのデータをDtoに変換するとTimestampはDateTimeに変換される', () {
        final mockDoc = _createDocument(
          data: {
            'accountId': 'account001',
            'ownerId': 'admin001',
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
          },
        );

        final dto = MemberMapper.fromFirestore(mockDoc);

        expect(dto.id, 'member001');
        expect(dto.accountId, 'account001');
        expect(dto.ownerId, 'admin001');
        expect(dto.hiraganaFirstName, 'たろう');
        expect(dto.hiraganaLastName, 'やまだ');
        expect(dto.kanjiFirstName, '太郎');
        expect(dto.kanjiLastName, '山田');
        expect(dto.firstName, 'Taro');
        expect(dto.lastName, 'Yamada');
        expect(dto.displayName, 'たろちゃん');
        expect(dto.type, '一般');
        expect(dto.birthday, DateTime(2000, 1, 1));
        expect(dto.gender, 'male');
        expect(dto.email, 'taro@example.com');
        expect(dto.phoneNumber, '090-1234-5678');
        expect(dto.passportNumber, 'A1234567');
        expect(dto.passportExpiration, '2030-01-01');
      });

      test('Firestoreのデータが一部欠けていてもデフォルト値を適用する', () {
        final mockDoc = _createDocument(
          id: 'member002',
          data: {'displayName': 'ゲストユーザー', 'type': 'guest'},
        );

        final dto = MemberMapper.fromFirestore(mockDoc);

        expect(dto.id, 'member002');
        expect(dto.displayName, 'ゲストユーザー');
        expect(dto.type, 'guest');
        expect(dto.accountId, isNull);
        expect(dto.ownerId, isNull);
        expect(dto.birthday, isNull);
        expect(dto.email, isNull);
      });

      test('displayNameが未設定の場合は空文字が設定される', () {
        final mockDoc = _createDocument(
          id: 'member003',
          data: {'firstName': 'Test', 'lastName': 'User'},
        );

        final dto = MemberMapper.fromFirestore(mockDoc);

        expect(dto.id, 'member003');
        expect(dto.displayName, '');
        expect(dto.firstName, 'Test');
        expect(dto.lastName, 'User');
      });

      test('DocumentSnapshotのdataがnullでも空のDtoを返す', () {
        final mockDoc = _createDocument(id: 'member004', data: null);

        final dto = MemberMapper.fromFirestore(mockDoc);

        expect(dto.id, 'member004');
        expect(dto.displayName, '');
        expect(dto.accountId, isNull);
        expect(dto.ownerId, isNull);
      });
    });

    group('toDto', () {
      test('MemberエンティティをDtoに正しく変換する', () {
        final member = _createMember(
          id: 'member-1',
          accountId: 'account-1',
          ownerId: 'owner-1',
          hiraganaFirstName: 'たろう',
          hiraganaLastName: 'やまだ',
          kanjiFirstName: '太郎',
          kanjiLastName: '山田',
          firstName: 'Taro',
          lastName: 'Yamada',
          type: 'family',
          birthday: DateTime(1990, 1, 1),
          gender: 'male',
          email: 'taro@example.com',
          phoneNumber: '09012345678',
          passportNumber: 'AB1234567',
          passportExpiration: '2030-01-01',
        );

        final dto = MemberMapper.toDto(member);

        expect(dto.id, 'member-1');
        expect(dto.accountId, 'account-1');
        expect(dto.ownerId, 'owner-1');
        expect(dto.hiraganaFirstName, 'たろう');
        expect(dto.hiraganaLastName, 'やまだ');
        expect(dto.kanjiFirstName, '太郎');
        expect(dto.kanjiLastName, '山田');
        expect(dto.firstName, 'Taro');
        expect(dto.lastName, 'Yamada');
        expect(dto.displayName, 'タロちゃん');
        expect(dto.type, 'family');
        expect(dto.birthday, DateTime(1990, 1, 1));
        expect(dto.gender, 'male');
        expect(dto.email, 'taro@example.com');
        expect(dto.phoneNumber, '09012345678');
        expect(dto.passportNumber, 'AB1234567');
        expect(dto.passportExpiration, '2030-01-01');
      });

      test('オプショナルフィールドがnullのエンティティはDtoでもnullのままになる', () {
        final member = _createMember(id: 'member-2', displayName: 'ハナコ');

        final dto = MemberMapper.toDto(member);

        expect(dto.id, 'member-2');
        expect(dto.accountId, isNull);
        expect(dto.ownerId, isNull);
        expect(dto.hiraganaFirstName, isNull);
        expect(dto.kanjiFirstName, isNull);
        expect(dto.firstName, isNull);
        expect(dto.type, isNull);
        expect(dto.birthday, isNull);
        expect(dto.gender, isNull);
        expect(dto.email, isNull);
        expect(dto.phoneNumber, isNull);
        expect(dto.passportNumber, isNull);
        expect(dto.passportExpiration, isNull);
      });
    });

    group('toEntity', () {
      test('MemberDtoをエンティティに正しく変換する', () {
        final dto = _createMemberDto(
          id: 'member-3',
          accountId: 'account-3',
          ownerId: 'owner-3',
          hiraganaFirstName: 'じろう',
          hiraganaLastName: 'さとう',
          kanjiFirstName: '次郎',
          kanjiLastName: '佐藤',
          firstName: 'Jiro',
          lastName: 'Sato',
          displayName: 'ジロー',
          type: 'friend',
          birthday: DateTime(1992, 2, 2),
          gender: 'male',
          email: 'jiro@example.com',
          phoneNumber: '08098765432',
          passportNumber: 'CD7654321',
          passportExpiration: '2031-02-02',
        );

        final entity = MemberMapper.toEntity(dto);

        expect(entity.id, 'member-3');
        expect(entity.accountId, 'account-3');
        expect(entity.ownerId, 'owner-3');
        expect(entity.hiraganaFirstName, 'じろう');
        expect(entity.hiraganaLastName, 'さとう');
        expect(entity.kanjiFirstName, '次郎');
        expect(entity.kanjiLastName, '佐藤');
        expect(entity.firstName, 'Jiro');
        expect(entity.lastName, 'Sato');
        expect(entity.displayName, 'ジロー');
        expect(entity.type, 'friend');
        expect(entity.birthday, DateTime(1992, 2, 2));
        expect(entity.gender, 'male');
        expect(entity.email, 'jiro@example.com');
        expect(entity.phoneNumber, '08098765432');
        expect(entity.passportNumber, 'CD7654321');
        expect(entity.passportExpiration, '2031-02-02');
      });

      test('オプショナルフィールドがnullのDtoでもnullのままエンティティに設定される', () {
        final dto = _createMemberDto(id: 'member-4', displayName: 'ボブ');

        final entity = MemberMapper.toEntity(dto);

        expect(entity.id, 'member-4');
        expect(entity.accountId, isNull);
        expect(entity.ownerId, isNull);
        expect(entity.hiraganaFirstName, isNull);
        expect(entity.kanjiFirstName, isNull);
        expect(entity.firstName, isNull);
        expect(entity.displayName, 'ボブ');
        expect(entity.type, isNull);
        expect(entity.birthday, isNull);
        expect(entity.gender, isNull);
        expect(entity.email, isNull);
        expect(entity.phoneNumber, isNull);
        expect(entity.passportNumber, isNull);
        expect(entity.passportExpiration, isNull);
      });
    });

    group('リスト変換', () {
      test('エンティティリストをDtoリストに変換する', () {
        final members = [
          _createMember(id: 'member-5', displayName: 'ケン'),
          _createMember(id: 'member-6', displayName: 'リナ'),
        ];

        final dtos = MemberMapper.toDtoList(members);

        expect(dtos, hasLength(2));
        expect(dtos[0].id, 'member-5');
        expect(dtos[0].displayName, 'ケン');
        expect(dtos[1].id, 'member-6');
        expect(dtos[1].displayName, 'リナ');
      });

      test('Dtoリストをエンティティリストに変換する', () {
        final dtos = [
          _createMemberDto(id: 'member-7', displayName: 'アヤ'),
          _createMemberDto(id: 'member-8', displayName: 'ユウ'),
        ];

        final entities = MemberMapper.toEntityList(dtos);

        expect(entities, hasLength(2));
        expect(entities[0].id, 'member-7');
        expect(entities[0].displayName, 'アヤ');
        expect(entities[1].id, 'member-8');
        expect(entities[1].displayName, 'ユウ');
      });

      test('空のリストは空のまま変換される', () {
        expect(MemberMapper.toDtoList(const <Member>[]), isEmpty);
        expect(MemberMapper.toEntityList(const <MemberDto>[]), isEmpty);
      });
    });
  });
}
