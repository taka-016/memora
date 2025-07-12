import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/update_group_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/repositories/group_repository.dart';

import 'update_group_usecase_test.mocks.dart';

@GenerateMocks([GroupRepository])
void main() {
  late UpdateGroupUsecase usecase;
  late MockGroupRepository mockGroupRepository;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    usecase = UpdateGroupUsecase(mockGroupRepository);
  });

  group('UpdateGroupUsecase', () {
    test('should update group in repository', () async {
      // arrange
      final group = Group(
        id: 'group123',
        name: 'Updated Group',
        administratorId: 'admin123',
      );

      when(mockGroupRepository.updateGroup(group)).thenAnswer((_) async => {});

      // act
      await usecase.execute(group);

      // assert
      verify(mockGroupRepository.updateGroup(group));
    });

    test('should complete without error for valid group', () async {
      // arrange
      final group = Group(
        id: 'group123',
        name: 'Updated Group',
        administratorId: 'admin123',
      );

      when(mockGroupRepository.updateGroup(group)).thenAnswer((_) async => {});

      // act & assert
      expect(() => usecase.execute(group), returnsNormally);
    });
  });
}
