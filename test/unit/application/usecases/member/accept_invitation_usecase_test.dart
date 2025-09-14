import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/accept_invitation_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/entities/member_invitation.dart';
import 'package:memora/domain/repositories/member_invitation_repository.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'accept_invitation_usecase_test.mocks.dart';

@GenerateMocks([MemberInvitationRepository, MemberRepository])
void main() {
  late AcceptInvitationUseCase useCase;
  late MockMemberInvitationRepository mockMemberInvitationRepository;
  late MockMemberRepository mockMemberRepository;

  setUp(() {
    mockMemberInvitationRepository = MockMemberInvitationRepository();
    mockMemberRepository = MockMemberRepository();
    useCase = AcceptInvitationUseCase(
      mockMemberInvitationRepository,
      mockMemberRepository,
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
      const member = Member(id: 'invitee-id', displayName: 'Invitee User');
      final updatedMember = member.copyWith(accountId: userId);

      when(
        mockMemberInvitationRepository.getByInvitationCode(invitationCode),
      ).thenAnswer((_) async => memberInvitation);
      when(
        mockMemberRepository.getMemberById('invitee-id'),
      ).thenAnswer((_) async => member);
      when(
        mockMemberRepository.updateMember(updatedMember),
      ).thenAnswer((_) async {});

      // Act
      final result = await useCase.execute(invitationCode, userId);

      // Assert
      expect(result, isTrue);
      verify(
        mockMemberInvitationRepository.getByInvitationCode(invitationCode),
      ).called(1);
      verify(mockMemberRepository.getMemberById('invitee-id')).called(1);
      verify(mockMemberRepository.updateMember(updatedMember)).called(1);
    });

    test('招待コードが存在しない場合falseを返す', () async {
      // Arrange
      const invitationCode = 'invalid-code';
      const userId = 'user-id';
      when(
        mockMemberInvitationRepository.getByInvitationCode(invitationCode),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(invitationCode, userId);

      // Assert
      expect(result, isFalse);
      verify(
        mockMemberInvitationRepository.getByInvitationCode(invitationCode),
      ).called(1);
      verifyNever(mockMemberRepository.getMemberById(any));
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
        mockMemberInvitationRepository.getByInvitationCode(invitationCode),
      ).thenAnswer((_) async => memberInvitation);
      when(
        mockMemberRepository.getMemberById('invitee-id'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(invitationCode, userId);

      // Assert
      expect(result, isFalse);
      verify(
        mockMemberInvitationRepository.getByInvitationCode(invitationCode),
      ).called(1);
      verify(mockMemberRepository.getMemberById('invitee-id')).called(1);
      verifyNever(mockMemberRepository.saveMember(any));
    });
  });
}
