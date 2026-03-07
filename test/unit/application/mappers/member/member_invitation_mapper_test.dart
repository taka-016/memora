import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_invitation_dto.dart';
import 'package:memora/application/mappers/member/member_invitation_mapper.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';

void main() {
  group('MemberInvitationMapper', () {
    test('Dtoからエンティティへ変換できる', () {
      final dto = MemberInvitationDto(
        id: 'inv-1',
        inviteeId: 'm1',
        inviterId: 'm2',
        invitationCode: 'CODE',
      );

      final entity = MemberInvitationMapper.toEntity(dto);

      expect(entity.id, 'inv-1');
      expect(entity.inviteeId, 'm1');
      expect(entity.inviterId, 'm2');
      expect(entity.invitationCode, 'CODE');
    });

    test('エンティティからDtoへ変換できる', () {
      const entity = MemberInvitation(
        id: 'inv-2',
        inviteeId: 'm3',
        inviterId: 'm4',
        invitationCode: 'CODE2',
      );

      final dto = MemberInvitationMapper.toDto(entity);

      expect(dto.id, 'inv-2');
      expect(dto.inviteeId, 'm3');
      expect(dto.inviterId, 'm4');
      expect(dto.invitationCode, 'CODE2');
    });

    test('Dtoリストをエンティティリストに変換できる', () {
      final dtos = [
        MemberInvitationDto(
          id: 'inv-1',
          inviteeId: 'm1',
          inviterId: 'm2',
          invitationCode: 'C1',
        ),
      ];

      final entities = MemberInvitationMapper.toEntityList(dtos);

      expect(entities, hasLength(1));
      expect(entities.first.id, 'inv-1');
    });

    test('エンティティリストをDtoリストに変換できる', () {
      const entities = [
        MemberInvitation(
          id: 'inv-1',
          inviteeId: 'm1',
          inviterId: 'm2',
          invitationCode: 'C1',
        ),
      ];

      final dtos = MemberInvitationMapper.toDtoList(entities);

      expect(dtos, hasLength(1));
      expect(dtos.first.id, 'inv-1');
    });
  });
}
