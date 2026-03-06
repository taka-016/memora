import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_invitation_dto.dart';
import 'package:memora/application/mappers/member/member_invitation_mapper.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';

void main() {
  group('MemberInvitationMapper', () {
    test('MemberInvitationDtoをエンティティに変換できる', () {
      final dto = MemberInvitationDto(
        id: 'inv-1',
        inviteeId: 'invitee-1',
        inviterId: 'inviter-1',
        invitationCode: 'CODE1',
      );

      final entity = MemberInvitationMapper.toEntity(dto);

      expect(entity.id, 'inv-1');
      expect(entity.inviteeId, 'invitee-1');
      expect(entity.inviterId, 'inviter-1');
      expect(entity.invitationCode, 'CODE1');
    });

    test('MemberInvitationエンティティをDtoに変換できる', () {
      const entity = MemberInvitation(
        id: 'inv-2',
        inviteeId: 'invitee-2',
        inviterId: 'inviter-2',
        invitationCode: 'CODE2',
      );

      final dto = MemberInvitationMapper.toDto(entity);

      expect(dto.id, 'inv-2');
      expect(dto.inviteeId, 'invitee-2');
      expect(dto.inviterId, 'inviter-2');
      expect(dto.invitationCode, 'CODE2');
    });

    test('リスト変換ができる', () {
      const entities = [
        MemberInvitation(
          id: 'inv-1',
          inviteeId: 'a',
          inviterId: 'b',
          invitationCode: 'x',
        ),
      ];

      final dtos = MemberInvitationMapper.toDtoList(entities);
      final restored = MemberInvitationMapper.toEntityList(dtos);

      expect(dtos, hasLength(1));
      expect(restored.first.id, 'inv-1');
    });
  });
}
