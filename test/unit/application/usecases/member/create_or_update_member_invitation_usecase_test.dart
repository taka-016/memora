import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/create_or_update_member_invitation_usecase.dart';
import 'package:memora/domain/entities/member_invitation.dart';
import 'package:memora/domain/repositories/member_invitation_repository.dart';

import 'create_or_update_member_invitation_usecase_test.mocks.dart';

@GenerateMocks([MemberInvitationRepository])
void main() {
  late MockMemberInvitationRepository mockMemberInvitationRepository;
  late CreateOrUpdateMemberInvitationUsecase usecase;

  setUp(() {
    mockMemberInvitationRepository = MockMemberInvitationRepository();
    usecase = CreateOrUpdateMemberInvitationUsecase(
      mockMemberInvitationRepository,
    );
  });

  group('CreateOrUpdateMemberInvitationUsecase', () {
    test('既存の招待がない場合、新規作成される', () async {
      // Arrange
      const inviteeId = 'invitee123';
      const inviterId = 'inviter456';

      when(
        mockMemberInvitationRepository.getByInviteeId(inviteeId),
      ).thenAnswer((_) async => null);

      // Act
      final invitationCode = await usecase.execute(
        inviteeId: inviteeId,
        inviterId: inviterId,
      );

      // Assert
      expect(invitationCode, isNotNull);
      expect(invitationCode, isNotEmpty);

      // 新規作成のsaveが呼ばれることを確認
      verify(mockMemberInvitationRepository.save(any)).called(1);
    });

    test('既存の招待がある場合、更新される', () async {
      // Arrange
      const inviteeId = 'invitee123';
      const inviterId = 'inviter456';
      const existingInvitation = MemberInvitation(
        id: 'existing123',
        inviteeId: inviteeId,
        inviterId: 'old_inviter',
        invitationCode: 'old_code',
      );

      when(
        mockMemberInvitationRepository.getByInviteeId(inviteeId),
      ).thenAnswer((_) async => existingInvitation);

      // Act
      final invitationCode = await usecase.execute(
        inviteeId: inviteeId,
        inviterId: inviterId,
      );

      // Assert
      expect(invitationCode, isNotNull);
      expect(invitationCode, isNotEmpty);
      expect(invitationCode, isNot(equals('old_code'))); // 新しいコードが生成される

      // 更新のsaveが呼ばれることを確認
      verify(mockMemberInvitationRepository.save(any)).called(1);
    });

    test('招待コードはUUID形式で生成される', () async {
      // Arrange
      const inviteeId = 'invitee123';
      const inviterId = 'inviter456';

      when(
        mockMemberInvitationRepository.getByInviteeId(inviteeId),
      ).thenAnswer((_) async => null);

      // Act
      final invitationCode = await usecase.execute(
        inviteeId: inviteeId,
        inviterId: inviterId,
      );

      // Assert
      // UUID形式かチェック（36文字、ハイフンを含む）
      expect(invitationCode.length, 36);
      expect(invitationCode.contains('-'), true);
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        ).hasMatch(invitationCode),
        true,
      );
    });
  });
}
