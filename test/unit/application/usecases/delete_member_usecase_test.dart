import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/delete_member_usecase.dart';
import 'package:memora/domain/repositories/member_repository.dart';

import 'delete_member_usecase_test.mocks.dart';

@GenerateMocks([MemberRepository])
void main() {
  late DeleteMemberUsecase usecase;
  late MockMemberRepository mockMemberRepository;

  setUp(() {
    mockMemberRepository = MockMemberRepository();
    usecase = DeleteMemberUsecase(mockMemberRepository);
  });

  group('DeleteMemberUsecase', () {
    test('should delete member by ID', () async {
      // Arrange
      const memberId = 'member-to-delete-id';

      when(mockMemberRepository.deleteMember(any)).thenAnswer((_) async {});

      // Act
      await usecase.execute(memberId);

      // Assert
      verify(mockMemberRepository.deleteMember(memberId)).called(1);
    });

    test('should handle empty member ID', () async {
      // Arrange
      const memberId = '';

      when(mockMemberRepository.deleteMember(any)).thenAnswer((_) async {});

      // Act
      await usecase.execute(memberId);

      // Assert
      verify(mockMemberRepository.deleteMember(memberId)).called(1);
    });
  });
}
