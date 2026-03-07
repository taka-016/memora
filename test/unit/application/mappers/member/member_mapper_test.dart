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
      );

      final dto = MemberMapper.toDto(member);

      expect(dto.id, 'member-1');
      expect(dto.accountId, 'account-1');
      expect(dto.ownerId, 'owner-1');
      expect(dto.displayName, 'タロウ');
    });

    test('MemberDtoをMemberエンティティに変換できる', () {
      final dto = MemberDto(
        id: 'member-2',
        accountId: 'account-2',
        ownerId: 'owner-2',
        displayName: 'ハナコ',
      );

      final entity = MemberMapper.toEntity(dto);

      expect(entity.id, 'member-2');
      expect(entity.accountId, 'account-2');
      expect(entity.ownerId, 'owner-2');
      expect(entity.displayName, 'ハナコ');
    });

    test('MemberリストをMemberDtoリストに変換できる', () {
      final members = [
        Member(id: 'member-1', displayName: 'A'),
        Member(id: 'member-2', displayName: 'B'),
      ];

      final dtos = MemberMapper.toDtoList(members);

      expect(dtos, hasLength(2));
      expect(dtos[0].id, 'member-1');
      expect(dtos[1].id, 'member-2');
    });

    test('MemberDtoリストをMemberリストに変換できる', () {
      final dtos = [
        MemberDto(id: 'member-1', displayName: 'A'),
        MemberDto(id: 'member-2', displayName: 'B'),
      ];

      final entities = MemberMapper.toEntityList(dtos);

      expect(entities, hasLength(2));
      expect(entities[0].id, 'member-1');
      expect(entities[1].id, 'member-2');
    });
  });
}
