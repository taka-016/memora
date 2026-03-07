import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/member/update_member_usecase.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';

import 'update_member_usecase_test.mocks.dart';

@GenerateMocks([MemberRepository])
void main() {
  late UpdateMemberUsecase usecase;
  late MockMemberRepository mockMemberRepository;

  setUp(() {
    mockMemberRepository = MockMemberRepository();
    usecase = UpdateMemberUsecase(mockMemberRepository);
  });

  group('UpdateMemberUsecase', () {
    test('メンバー情報を更新すること', () async {
      // Arrange
      final updatedMember = MemberDto(
        id: 'member-id',
        accountId: null,
        ownerId: 'admin-member-id',
        displayName: '更新後メンバー',
        kanjiLastName: '更新',
        kanjiFirstName: '太郎',
        hiraganaLastName: 'コウシン',
        hiraganaFirstName: 'タロウ',
        gender: 'male',
        birthday: DateTime(1995, 8, 20),
      );

      when(mockMemberRepository.updateMember(any)).thenAnswer((_) async {});

      // Act
      await usecase.execute(updatedMember);

      // Assert
      final captured = verify(
        mockMemberRepository.updateMember(captureAny),
      ).captured;
      final member = captured.single as Member;
      expect(member.id, updatedMember.id);
      expect(member.displayName, updatedMember.displayName);
      expect(member.ownerId, updatedMember.ownerId);
    });

    test('最小限のデータでメンバーを更新すること', () async {
      // Arrange
      final updatedMember = MemberDto(id: 'member-id', displayName: '更新表示名');

      when(mockMemberRepository.updateMember(any)).thenAnswer((_) async {});

      // Act
      await usecase.execute(updatedMember);

      // Assert
      final captured = verify(
        mockMemberRepository.updateMember(captureAny),
      ).captured;
      final member = captured.single as Member;
      expect(member.id, updatedMember.id);
      expect(member.displayName, updatedMember.displayName);
    });
  });
}
