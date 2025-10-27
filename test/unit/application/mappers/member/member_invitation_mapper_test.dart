import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_invitation_dto.dart';
import 'package:memora/application/mappers/member/member_invitation_mapper.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'member_invitation_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('MemberInvitationMapper', () {
    test('FirestoreのドキュメントからMemberInvitationDtoへ変換できる', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('invite-001');
      when(mockDoc.data()).thenReturn({
        'inviteeId': 'member-001',
        'inviterId': 'member-002',
        'invitationCode': 'CODE123',
      });

      final dto = MemberInvitationMapper.fromFirestore(mockDoc);

      expect(dto.id, 'invite-001');
      expect(dto.inviteeId, 'member-001');
      expect(dto.inviterId, 'member-002');
      expect(dto.invitationCode, 'CODE123');
    });

    test('Firestoreの値が存在しない場合は空文字列で変換する', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('invite-002');
      when(mockDoc.data()).thenReturn(null);

      final dto = MemberInvitationMapper.fromFirestore(mockDoc);

      expect(dto.id, 'invite-002');
      expect(dto.inviteeId, '');
      expect(dto.inviterId, '');
      expect(dto.invitationCode, '');
    });

    test('MemberInvitationDtoからエンティティへ変換できる', () {
      final dto = MemberInvitationDto(
        id: 'invite-003',
        inviteeId: 'member-010',
        inviterId: 'member-020',
        invitationCode: 'CODE999',
      );

      final entity = MemberInvitationMapper.toEntity(dto);

      expect(
        entity,
        const MemberInvitation(
          id: 'invite-003',
          inviteeId: 'member-010',
          inviterId: 'member-020',
          invitationCode: 'CODE999',
        ),
      );
    });

    test('MemberInvitationエンティティからDtoへ変換できる', () {
      const entity = MemberInvitation(
        id: 'invite-004',
        inviteeId: 'member-030',
        inviterId: 'member-040',
        invitationCode: 'CODEABC',
      );

      final dto = MemberInvitationMapper.toDto(entity);

      expect(dto.id, 'invite-004');
      expect(dto.inviteeId, 'member-030');
      expect(dto.inviterId, 'member-040');
      expect(dto.invitationCode, 'CODEABC');
    });

    test('Dtoリストからエンティティリストへ変換できる', () {
      final dtos = [
        MemberInvitationDto(
          id: 'invite-101',
          inviteeId: 'member-101',
          inviterId: 'member-201',
          invitationCode: 'AAA111',
        ),
        MemberInvitationDto(
          id: 'invite-102',
          inviteeId: 'member-102',
          inviterId: 'member-202',
          invitationCode: 'BBB222',
        ),
      ];

      final entities = MemberInvitationMapper.toEntityList(dtos);

      expect(entities.length, 2);
      expect(entities[0].id, 'invite-101');
      expect(entities[1].invitationCode, 'BBB222');
    });

    test('エンティティリストからDtoリストへ変換できる', () {
      const entities = [
        MemberInvitation(
          id: 'invite-201',
          inviteeId: 'member-301',
          inviterId: 'member-401',
          invitationCode: 'CCC333',
        ),
        MemberInvitation(
          id: 'invite-202',
          inviteeId: 'member-302',
          inviterId: 'member-402',
          invitationCode: 'DDD444',
        ),
      ];

      final dtos = MemberInvitationMapper.toDtoList(entities);

      expect(dtos.length, 2);
      expect(dtos[0].id, 'invite-201');
      expect(dtos[1].invitationCode, 'DDD444');
    });
  });
}
