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
        displayName: 'タロウ',
        birthday: DateTime(1990, 1, 1),
      );

      final dto = MemberMapper.toDto(member);

      expect(dto.id, 'member-1');
      expect(dto.accountId, 'account-1');
      expect(dto.ownerId, 'owner-1');
      expect(dto.displayName, 'タロウ');
      expect(dto.birthday, DateTime(1990, 1, 1));
    });

    test('MemberDtoをMemberエンティティに変換できる', () {
      final dto = MemberDto(
        id: 'member-2',
        accountId: 'account-2',
        ownerId: 'owner-2',
        displayName: 'ハナコ',
        birthday: DateTime(1992, 2, 2),
      );

      final entity = MemberMapper.toEntity(dto);

      expect(entity.id, 'member-2');
      expect(entity.accountId, 'account-2');
      expect(entity.ownerId, 'owner-2');
      expect(entity.displayName, 'ハナコ');
      expect(entity.birthday, DateTime(1992, 2, 2));
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
