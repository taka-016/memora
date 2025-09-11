import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/create_member_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/member_repository.dart';

import 'create_member_usecase_test.mocks.dart';

@GenerateMocks([MemberRepository])
void main() {
  late CreateMemberUsecase usecase;
  late MockMemberRepository mockMemberRepository;

  setUp(() {
    mockMemberRepository = MockMemberRepository();
    usecase = CreateMemberUsecase(mockMemberRepository);
  });

  group('CreateMemberUsecase', () {
    test('新しいメンバーを作成すること', () async {
      // Arrange
      final editedMember = Member(
        id: 'edited-member-id',
        displayName: '新メンバー',
        kanjiLastName: '新田',
        kanjiFirstName: '三郎',
        hiraganaLastName: 'ニッタ',
        hiraganaFirstName: 'サブロウ',
        gender: 'male',
        birthday: DateTime(2005, 3, 15),
      );
      const ownerId = 'admin-member-id';

      when(mockMemberRepository.saveMember(any)).thenAnswer((_) async {});

      // Act
      await usecase.execute(editedMember, ownerId);

      // Assert
      final captured = verify(
        mockMemberRepository.saveMember(captureAny),
      ).captured;
      final savedMember = captured[0] as Member;
      expect(savedMember.ownerId, ownerId);
      expect(savedMember.displayName, editedMember.displayName);
      expect(savedMember.kanjiLastName, editedMember.kanjiLastName);
      expect(savedMember.kanjiFirstName, editedMember.kanjiFirstName);
      expect(savedMember.hiraganaLastName, editedMember.hiraganaLastName);
      expect(savedMember.hiraganaFirstName, editedMember.hiraganaFirstName);
      expect(savedMember.gender, editedMember.gender);
      expect(savedMember.birthday, editedMember.birthday);
      expect(savedMember.id, isNot(editedMember.id)); // 新しいIDが生成されること
    });

    test('最小限のデータでメンバーを作成すること', () async {
      // Arrange
      final editedMember = Member(id: 'edited-member-id', displayName: 'ミニマル');
      const ownerId = 'admin-member-id';

      when(mockMemberRepository.saveMember(any)).thenAnswer((_) async {});

      // Act
      await usecase.execute(editedMember, ownerId);

      // Assert
      final captured = verify(
        mockMemberRepository.saveMember(captureAny),
      ).captured;
      final savedMember = captured[0] as Member;
      expect(savedMember.ownerId, ownerId);
      expect(savedMember.displayName, editedMember.displayName);
      expect(savedMember.id, isNot(editedMember.id)); // 新しいIDが生成されること
    });
  });
}
