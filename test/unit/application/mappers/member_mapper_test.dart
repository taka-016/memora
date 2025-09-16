import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/member_mapper.dart';
import 'package:memora/domain/entities/member.dart';

void main() {
  group('MemberMapper', () {
    test('MemberエンティティをMemberDtoに正しく変換する', () {
      // Arrange
      final member = Member(
        id: 'member-1',
        accountId: 'account-1',
        ownerId: 'owner-1',
        hiraganaFirstName: 'たろう',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '太郎',
        kanjiLastName: '山田',
        firstName: 'Taro',
        lastName: 'Yamada',
        displayName: 'タロちゃん',
        type: 'family',
        birthday: DateTime(1990, 1, 1),
        gender: 'male',
        email: 'taro@example.com',
        phoneNumber: '09012345678',
        passportNumber: 'AB1234567',
        passportExpiration: '2030-01-01',
      );

      // Act
      final dto = MemberMapper.toDto(member);

      // Assert
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

    test('オプショナルプロパティがnullのMemberエンティティをDtoに変換する', () {
      // Arrange
      final member = Member(
        id: 'member-2',
        displayName: 'ハナコ',
      );

      // Act
      final dto = MemberMapper.toDto(member);

      // Assert
      expect(dto.id, 'member-2');
      expect(dto.accountId, isNull);
      expect(dto.ownerId, isNull);
      expect(dto.hiraganaFirstName, isNull);
      expect(dto.hiraganaLastName, isNull);
      expect(dto.kanjiFirstName, isNull);
      expect(dto.kanjiLastName, isNull);
      expect(dto.firstName, isNull);
      expect(dto.lastName, isNull);
      expect(dto.displayName, 'ハナコ');
      expect(dto.type, isNull);
      expect(dto.birthday, isNull);
      expect(dto.gender, isNull);
      expect(dto.email, isNull);
      expect(dto.phoneNumber, isNull);
      expect(dto.passportNumber, isNull);
      expect(dto.passportExpiration, isNull);
    });

    test('MemberDtoをMemberエンティティに正しく変換する', () {
      // Arrange
      final dto = MemberDto(
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

      // Act
      final entity = MemberMapper.toEntity(dto);

      // Assert
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

    test('オプショナルプロパティがnullのDtoをエンティティに変換する', () {
      // Arrange
      final dto = MemberDto(
        id: 'member-4',
        displayName: 'ボブ',
      );

      // Act
      final entity = MemberMapper.toEntity(dto);

      // Assert
      expect(entity.id, 'member-4');
      expect(entity.accountId, isNull);
      expect(entity.ownerId, isNull);
      expect(entity.hiraganaFirstName, isNull);
      expect(entity.hiraganaLastName, isNull);
      expect(entity.kanjiFirstName, isNull);
      expect(entity.kanjiLastName, isNull);
      expect(entity.firstName, isNull);
      expect(entity.lastName, isNull);
      expect(entity.displayName, 'ボブ');
      expect(entity.type, isNull);
      expect(entity.birthday, isNull);
      expect(entity.gender, isNull);
      expect(entity.email, isNull);
      expect(entity.phoneNumber, isNull);
      expect(entity.passportNumber, isNull);
      expect(entity.passportExpiration, isNull);
    });

    test('Memberエンティティのリストを正しくDtoリストに変換する', () {
      // Arrange
      final members = [
        Member(
          id: 'member-5',
          displayName: 'ケン',
        ),
        Member(
          id: 'member-6',
          displayName: 'リナ',
        ),
      ];

      // Act
      final dtos = MemberMapper.toDtoList(members);

      // Assert
      expect(dtos.length, 2);
      expect(dtos[0].id, 'member-5');
      expect(dtos[0].displayName, 'ケン');
      expect(dtos[1].id, 'member-6');
      expect(dtos[1].displayName, 'リナ');
    });

    test('MemberDtoのリストを正しくエンティティリストに変換する', () {
      // Arrange
      final dtos = [
        MemberDto(
          id: 'member-7',
          displayName: 'アヤ',
        ),
        MemberDto(
          id: 'member-8',
          displayName: 'ユウ',
        ),
      ];

      // Act
      final entities = MemberMapper.toEntityList(dtos);

      // Assert
      expect(entities.length, 2);
      expect(entities[0].id, 'member-7');
      expect(entities[0].displayName, 'アヤ');
      expect(entities[1].id, 'member-8');
      expect(entities[1].displayName, 'ユウ');
    });

    test('空のリストを変換する', () {
      // Arrange
      final emptyMemberList = <Member>[];
      final emptyDtoList = <MemberDto>[];

      // Act
      final emptyDtoResult = MemberMapper.toDtoList(emptyMemberList);
      final emptyEntityResult = MemberMapper.toEntityList(emptyDtoList);

      // Assert
      expect(emptyDtoResult, isEmpty);
      expect(emptyEntityResult, isEmpty);
    });
  });
}
