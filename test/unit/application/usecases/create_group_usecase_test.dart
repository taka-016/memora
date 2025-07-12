import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/create_group_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/repositories/group_repository.dart';

import 'create_group_usecase_test.mocks.dart';

@GenerateMocks([GroupRepository])
void main() {
  late CreateGroupUsecase usecase;
  late MockGroupRepository mockGroupRepository;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    usecase = CreateGroupUsecase(mockGroupRepository);
  });

  group('CreateGroupUsecase', () {
    test('should save group to repository', () async {
      // arrange
      final group = Group(
        id: 'group123',
        name: 'Test Group',
        administratorId: 'admin123',
      );

      when(mockGroupRepository.saveGroup(group)).thenAnswer((_) async => {});

      // act
      await usecase.execute(group);

      // assert
      verify(mockGroupRepository.saveGroup(group));
    });

    test('should complete without error for valid group', () async {
      // arrange
      final group = Group(
        id: 'group123',
        name: 'Test Group',
        administratorId: 'admin123',
      );

      when(mockGroupRepository.saveGroup(group)).thenAnswer((_) async => {});

      // act & assert
      expect(() => usecase.execute(group), returnsNormally);
    });
  });
}
