import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/delete_group_usecase.dart';
import 'package:memora/domain/repositories/group_repository.dart';

import 'delete_group_usecase_test.mocks.dart';

@GenerateMocks([GroupRepository])
void main() {
  late DeleteGroupUsecase usecase;
  late MockGroupRepository mockGroupRepository;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    usecase = DeleteGroupUsecase(mockGroupRepository);
  });

  group('DeleteGroupUsecase', () {
    test('should delete group from repository', () async {
      // arrange
      const groupId = 'group123';

      when(
        mockGroupRepository.deleteGroup(groupId),
      ).thenAnswer((_) async => {});

      // act
      await usecase.execute(groupId);

      // assert
      verify(mockGroupRepository.deleteGroup(groupId));
    });

    test('should complete without error for valid group id', () async {
      // arrange
      const groupId = 'group123';

      when(
        mockGroupRepository.deleteGroup(groupId),
      ).thenAnswer((_) async => {});

      // act & assert
      expect(() => usecase.execute(groupId), returnsNormally);
    });
  });
}
