import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/usecases/group/update_group_usecase.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';

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
    test('リポジトリでグループを更新すること', () async {
      // arrange
      final group = GroupDto(
        id: 'group123',
        name: 'Updated Group',
        ownerId: 'admin123',
        members: const [],
      );

      when(mockGroupRepository.updateGroup(any)).thenAnswer((_) async => {});

      // act
      await usecase.execute(group);

      // assert
      final captured = verify(
        mockGroupRepository.updateGroup(captureAny),
      ).captured;
      final updatedGroup = captured.single as Group;
      expect(updatedGroup.id, group.id);
      expect(updatedGroup.name, group.name);
      expect(updatedGroup.ownerId, group.ownerId);
    });

    test('有効なグループに対してエラーなく完了すること', () async {
      // arrange
      final group = GroupDto(
        id: 'group123',
        name: 'Updated Group',
        ownerId: 'admin123',
        members: const [],
      );

      when(mockGroupRepository.updateGroup(any)).thenAnswer((_) async => {});

      // act & assert
      expect(() => usecase.execute(group), returnsNormally);
    });
  });
}
