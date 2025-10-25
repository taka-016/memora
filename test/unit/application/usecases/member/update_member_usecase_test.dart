import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
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
      final updatedMember = Member(
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
      verify(mockMemberRepository.updateMember(updatedMember)).called(1);
    });

    test('最小限のデータでメンバーを更新すること', () async {
      // Arrange
      final updatedMember = Member(id: 'member-id', displayName: '更新表示名');

      when(mockMemberRepository.updateMember(any)).thenAnswer((_) async {});

      // Act
      await usecase.execute(updatedMember);

      // Assert
      verify(mockMemberRepository.updateMember(updatedMember)).called(1);
    });
  });
}
