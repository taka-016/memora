import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/group/update_group_usecase.dart';
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
    test('リポジトリでグループを更新すること', () async {
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

    test('有効なグループに対してエラーなく完了すること', () async {
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
