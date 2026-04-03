import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_invitation_dto.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/create_or_update_member_invitation_usecase.dart';
import 'package:memora/domain/repositories/member/member_invitation_repository.dart';

import 'create_or_update_member_invitation_usecase_test.mocks.dart';

final _uuidV7Pattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

@GenerateMocks([MemberInvitationRepository, MemberInvitationQueryService])
void main() {
  late MockMemberInvitationRepository mockMemberInvitationRepository;
  late MockMemberInvitationQueryService mockMemberInvitationQueryService;
  late CreateOrUpdateMemberInvitationUsecase usecase;

  setUp(() {
    mockMemberInvitationRepository = MockMemberInvitationRepository();
    mockMemberInvitationQueryService = MockMemberInvitationQueryService();
    usecase = CreateOrUpdateMemberInvitationUsecase(
      mockMemberInvitationRepository,
      mockMemberInvitationQueryService,
    );
  });

  group('CreateOrUpdateMemberInvitationUsecase', () {
    test('既存の招待がない場合、新規作成される', () async {
      // Arrange
      const inviteeId = 'invitee123';
      const inviterId = 'inviter456';

      when(
        mockMemberInvitationQueryService.getByInviteeId(inviteeId),
      ).thenAnswer((_) async => null);

      // Act
      final invitationCode = await usecase.execute(
        inviteeId: inviteeId,
        inviterId: inviterId,
      );

      // Assert
      expect(invitationCode, isNotNull);
      expect(invitationCode, isNotEmpty);

      // 新規作成処理が呼ばれることを確認
      verify(
        mockMemberInvitationRepository.saveMemberInvitation(any),
      ).called(1);
    });

    test('既存の招待がある場合、更新される', () async {
      // Arrange
      const inviteeId = 'invitee123';
      const inviterId = 'inviter456';
      const existingInvitation = MemberInvitationDto(
        id: 'existing123',
        inviteeId: inviteeId,
        inviterId: 'old_inviter',
        invitationCode: 'old_code',
      );

      when(
        mockMemberInvitationQueryService.getByInviteeId(inviteeId),
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

      // 更新処理が呼ばれることを確認
      verify(
        mockMemberInvitationRepository.updateMemberInvitation(any),
      ).called(1);
    });

    test('招待コードはUUID v7形式で生成される', () async {
      // Arrange
      const inviteeId = 'invitee123';
      const inviterId = 'inviter456';

      when(
        mockMemberInvitationQueryService.getByInviteeId(inviteeId),
      ).thenAnswer((_) async => null);

      // Act
      final invitationCode = await usecase.execute(
        inviteeId: inviteeId,
        inviterId: inviterId,
      );

      // Assert
      expect(_uuidV7Pattern.hasMatch(invitationCode), isTrue);
    });
  });
}
