import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/get_member_by_invitation_code_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/entities/member_invitation.dart';
import 'package:memora/domain/repositories/member_invitation_repository.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'get_member_by_invitation_code_usecase_test.mocks.dart';

@GenerateMocks([MemberInvitationRepository, MemberRepository])
void main() {
  late GetMemberByInvitationCodeUseCase useCase;
  late MockMemberInvitationRepository mockMemberInvitationRepository;
  late MockMemberRepository mockMemberRepository;

  setUp(() {
    mockMemberInvitationRepository = MockMemberInvitationRepository();
    mockMemberRepository = MockMemberRepository();
    useCase = GetMemberByInvitationCodeUseCase(
      mockMemberInvitationRepository,
      mockMemberRepository,
    );
  });

  group('GetMemberByInvitationCodeUseCase', () {
    test('招待コードが存在する場合、メンバーを返す', () async {
      // Arrange
      const invitationCode = 'test-invitation-code';
      const memberInvitation = MemberInvitation(
        id: 'invitation-id',
        inviteeId: 'invitee-id',
        inviterId: 'inviter-id',
        invitationCode: invitationCode,
      );
      const member = Member(id: 'invitee-id', displayName: 'Invitee User');

      when(
        mockMemberInvitationRepository.getByInvitationCode(invitationCode),
      ).thenAnswer((_) async => memberInvitation);
      when(
        mockMemberRepository.getMemberById('invitee-id'),
      ).thenAnswer((_) async => member);

      // Act
      final result = await useCase.execute(invitationCode);

      // Assert
      expect(result, equals(member));
      verify(
        mockMemberInvitationRepository.getByInvitationCode(invitationCode),
      ).called(1);
      verify(mockMemberRepository.getMemberById('invitee-id')).called(1);
    });

    test('招待コードが存在しない場合、nullを返す', () async {
      // Arrange
      const invitationCode = 'invalid-code';
      when(
        mockMemberInvitationRepository.getByInvitationCode(invitationCode),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(invitationCode);

      // Assert
      expect(result, isNull);
      verify(
        mockMemberInvitationRepository.getByInvitationCode(invitationCode),
      ).called(1);
      verifyNever(mockMemberRepository.getMemberById(any));
    });

    test('メンバーが見つからない場合、nullを返す', () async {
      // Arrange
      const invitationCode = 'test-invitation-code';
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
      final result = await useCase.execute(invitationCode);

      // Assert
      expect(result, isNull);
      verify(
        mockMemberInvitationRepository.getByInvitationCode(invitationCode),
      ).called(1);
      verify(mockMemberRepository.getMemberById('invitee-id')).called(1);
    });
  });
}
