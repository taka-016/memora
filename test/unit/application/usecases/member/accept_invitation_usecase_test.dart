import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/accept_invitation_usecase.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';

import 'accept_invitation_usecase_test.mocks.dart';

@GenerateMocks([
  MemberInvitationQueryService,
  MemberRepository,
  MemberQueryService,
])
void main() {
  late AcceptInvitationUseCase useCase;
  late MockMemberInvitationQueryService mockMemberInvitationQueryService;
  late MockMemberRepository mockMemberRepository;
  late MockMemberQueryService mockMemberQueryService;

  setUp(() {
    mockMemberInvitationQueryService = MockMemberInvitationQueryService();
    mockMemberRepository = MockMemberRepository();
    mockMemberQueryService = MockMemberQueryService();
    useCase = AcceptInvitationUseCase(
      mockMemberInvitationQueryService,
      mockMemberRepository,
      mockMemberQueryService,
    );
  });

  group('AcceptInvitationUseCase', () {
    test('招待コードが存在し、メンバーのaccountIdを更新成功した場合trueを返す', () async {
      // Arrange
      const invitationCode = 'test-invitation-code';
      const userId = 'user-id';
      const memberInvitation = MemberInvitation(
        id: 'invitation-id',
        inviteeId: 'invitee-id',
        inviterId: 'inviter-id',
        invitationCode: invitationCode,
      );
      const member = MemberDto(id: 'invitee-id', displayName: 'Invitee User');
      final updatedMember = Member(
        id: 'invitee-id',
        displayName: 'Invitee User',
        accountId: userId,
      );

      when(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).thenAnswer((_) async => memberInvitation);
      when(
        mockMemberQueryService.getMemberById('invitee-id'),
      ).thenAnswer((_) async => member);
      when(
        mockMemberRepository.updateMember(updatedMember),
      ).thenAnswer((_) async {});

      // Act
      final result = await useCase.execute(invitationCode, userId);

      // Assert
      expect(result, isTrue);
      verify(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).called(1);
      verify(mockMemberQueryService.getMemberById('invitee-id')).called(1);
      verify(mockMemberRepository.updateMember(updatedMember)).called(1);
    });

    test('招待コードが存在しない場合falseを返す', () async {
      // Arrange
      const invitationCode = 'invalid-code';
      const userId = 'user-id';
      when(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(invitationCode, userId);

      // Assert
      expect(result, isFalse);
      verify(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).called(1);
      verifyNever(mockMemberQueryService.getMemberById(any));
      verifyNever(mockMemberRepository.saveMember(any));
    });

    test('メンバーが見つからない場合falseを返す', () async {
      // Arrange
      const invitationCode = 'test-invitation-code';
      const userId = 'user-id';
      const memberInvitation = MemberInvitation(
        id: 'invitation-id',
        inviteeId: 'invitee-id',
        inviterId: 'inviter-id',
        invitationCode: invitationCode,
      );

      when(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).thenAnswer((_) async => memberInvitation);
      when(
        mockMemberQueryService.getMemberById('invitee-id'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(invitationCode, userId);

      // Assert
      expect(result, isFalse);
      verify(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).called(1);
      verify(mockMemberQueryService.getMemberById('invitee-id')).called(1);
      verifyNever(mockMemberRepository.saveMember(any));
    });

    test('招待対象メンバーにaccountIdが既に存在する場合、更新せずfalseを返す', () async {
      // Arrange
      const invitationCode = 'test-invitation-code';
      const userId = 'new-user-id';
      const memberInvitation = MemberInvitation(
        id: 'invitation-id',
        inviteeId: 'invitee-id',
        inviterId: 'inviter-id',
        invitationCode: invitationCode,
      );
      const member = MemberDto(
        id: 'invitee-id',
        displayName: 'Invitee User',
        accountId: 'existing-account-id',
      );

      when(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).thenAnswer((_) async => memberInvitation);
      when(
        mockMemberQueryService.getMemberById('invitee-id'),
      ).thenAnswer((_) async => member);

      // Act
      final result = await useCase.execute(invitationCode, userId);

      // Assert
      expect(result, isFalse);
      verify(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).called(1);
      verify(mockMemberQueryService.getMemberById('invitee-id')).called(1);
      verifyNever(mockMemberRepository.updateMember(any));
    });
  });
}
