import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/create_member_usecase.dart';
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
    test('should create a new member', () async {
      // Arrange
      final newMember = Member(
        id: 'new-member-id',
        administratorId: 'admin-member-id',
        nickname: '新メンバー',
        kanjiLastName: '新田',
        kanjiFirstName: '三郎',
        hiraganaLastName: 'ニッタ',
        hiraganaFirstName: 'サブロウ',
        gender: 'male',
        birthday: DateTime(2005, 3, 15),
      );

      when(mockMemberRepository.saveMember(any)).thenAnswer((_) async {});

      // Act
      await usecase.execute(newMember);

      // Assert
      verify(mockMemberRepository.saveMember(newMember)).called(1);
    });

    test('should create member with minimal data', () async {
      // Arrange
      final newMember = Member(
        id: 'new-member-id',
        administratorId: 'admin-member-id',
        nickname: 'ミニマル',
      );

      when(mockMemberRepository.saveMember(any)).thenAnswer((_) async {});

      // Act
      await usecase.execute(newMember);

      // Assert
      verify(mockMemberRepository.saveMember(newMember)).called(1);
    });
  });
}
