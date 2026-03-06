import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/member/member_mapper.dart';
import 'package:memora/domain/entities/member/member.dart';

void main() {
  group('MemberMapper', () {
    test('MemberエンティティをMemberDtoに変換できる', () {
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
        displayName: 'タロウ',
        type: 'adult',
        birthday: DateTime(1990, 1, 1),
        gender: 'male',
        email: 'taro@example.com',
        phoneNumber: '090-1111-2222',
        passportNumber: 'TR1234567',
        passportExpiration: '2030-12-31',
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
      expect(dto.displayName, 'タロウ');
      expect(dto.type, 'adult');
      expect(dto.birthday, DateTime(1990, 1, 1));
      expect(dto.gender, 'male');
      expect(dto.email, 'taro@example.com');
      expect(dto.phoneNumber, '090-1111-2222');
      expect(dto.passportNumber, 'TR1234567');
      expect(dto.passportExpiration, '2030-12-31');
    });

    test('MemberDtoをMemberエンティティに変換できる', () {
      final dto = MemberDto(
        id: 'member-2',
        accountId: 'account-2',
        ownerId: 'owner-2',
        hiraganaFirstName: 'はなこ',
        hiraganaLastName: 'さとう',
        kanjiFirstName: '花子',
        kanjiLastName: '佐藤',
        firstName: 'Hanako',
        lastName: 'Sato',
        displayName: 'ハナコ',
        type: 'child',
        birthday: DateTime(1992, 2, 2),
        gender: 'female',
        email: 'hanako@example.com',
        phoneNumber: '090-3333-4444',
        passportNumber: 'HN7654321',
        passportExpiration: '2031-06-30',
      );

      final entity = MemberMapper.toEntity(dto);

      expect(entity.id, 'member-2');
      expect(entity.accountId, 'account-2');
      expect(entity.ownerId, 'owner-2');
      expect(entity.hiraganaFirstName, 'はなこ');
      expect(entity.hiraganaLastName, 'さとう');
      expect(entity.kanjiFirstName, '花子');
      expect(entity.kanjiLastName, '佐藤');
      expect(entity.firstName, 'Hanako');
      expect(entity.lastName, 'Sato');
      expect(entity.displayName, 'ハナコ');
      expect(entity.type, 'child');
      expect(entity.birthday, DateTime(1992, 2, 2));
      expect(entity.gender, 'female');
      expect(entity.email, 'hanako@example.com');
      expect(entity.phoneNumber, '090-3333-4444');
      expect(entity.passportNumber, 'HN7654321');
      expect(entity.passportExpiration, '2031-06-30');
    });

    test('リスト変換ができる', () {
      final members = [
        Member(id: 'member-1', displayName: 'A'),
        Member(id: 'member-2', displayName: 'B'),
      ];
      final dtos = MemberMapper.toDtoList(members);
      final restored = MemberMapper.toEntityList(dtos);

      expect(dtos, hasLength(2));
      expect(restored, hasLength(2));
      expect(restored[0].id, 'member-1');
      expect(restored[1].displayName, 'B');
    });
  });
}
