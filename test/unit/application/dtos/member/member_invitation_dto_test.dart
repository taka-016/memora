import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_invitation_dto.dart';

void main() {
  group('MemberInvitationDto', () {
    test('コンストラクタが正しく動作する', () {
      // Arrange
      const id = 'invitation-123';
      const inviteeId = 'member-456';
      const inviterId = 'member-789';
      const invitationCode = 'CODE123';

      // Act
      const dto = MemberInvitationDto(
        id: id,
        inviteeId: inviteeId,
        inviterId: inviterId,
        invitationCode: invitationCode,
      );

      // Assert
      expect(dto.id, id);
      expect(dto.inviteeId, inviteeId);
      expect(dto.inviterId, inviterId);
      expect(dto.invitationCode, invitationCode);
    });

    test('copyWithメソッドで値が正しく更新される', () {
      // Arrange
      const originalDto = MemberInvitationDto(
        id: 'invitation-123',
        inviteeId: 'member-456',
        inviterId: 'member-789',
        invitationCode: 'CODE123',
      );

      // Act
      final copiedDto = originalDto.copyWith(
        id: 'invitation-999',
        inviteeId: 'member-111',
        inviterId: 'member-222',
        invitationCode: 'CODE999',
      );

      // Assert
      expect(copiedDto.id, 'invitation-999');
      expect(copiedDto.inviteeId, 'member-111');
      expect(copiedDto.inviterId, 'member-222');
      expect(copiedDto.invitationCode, 'CODE999');
    });

    test('copyWithメソッドでnullを指定しても元の値が保持される', () {
      // Arrange
      const originalDto = MemberInvitationDto(
        id: 'invitation-123',
        inviteeId: 'member-456',
        inviterId: 'member-789',
        invitationCode: 'CODE123',
      );

      // Act
      final copiedDto = originalDto.copyWith();

      // Assert
      expect(copiedDto.id, 'invitation-123');
      expect(copiedDto.inviteeId, 'member-456');
      expect(copiedDto.inviterId, 'member-789');
      expect(copiedDto.invitationCode, 'CODE123');
    });

    test('同じ値を持つインスタンスは等しい', () {
      // Arrange
      const id = 'invitation-123';
      const inviteeId = 'member-456';
      const inviterId = 'member-789';
      const invitationCode = 'CODE123';

      const dto1 = MemberInvitationDto(
        id: id,
        inviteeId: inviteeId,
        inviterId: inviterId,
        invitationCode: invitationCode,
      );

      const dto2 = MemberInvitationDto(
        id: id,
        inviteeId: inviteeId,
        inviterId: inviterId,
        invitationCode: invitationCode,
      );

      // Act & Assert
      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
    });

    test('異なる値を持つインスタンスは等しくない', () {
      // Arrange
      const dto1 = MemberInvitationDto(
        id: 'invitation-123',
        inviteeId: 'member-456',
        inviterId: 'member-789',
        invitationCode: 'CODE123',
      );

      const dto2 = MemberInvitationDto(
        id: 'invitation-999',
        inviteeId: 'member-111',
        inviterId: 'member-222',
        invitationCode: 'CODE999',
      );

      // Act & Assert
      expect(dto1, isNot(equals(dto2)));
      expect(dto1.hashCode, isNot(equals(dto2.hashCode)));
    });
  });
}
