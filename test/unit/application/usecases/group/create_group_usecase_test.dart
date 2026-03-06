import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/usecases/group/create_group_usecase.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';

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
    test('グループをリポジトリに保存し、生成されたIDを返すこと', () async {
      // arrange
      final group = GroupDto(
        id: '',
        name: 'Test Group',
        ownerId: 'admin123',
        members: const [],
      );

      when(
        mockGroupRepository.saveGroup(any),
      ).thenAnswer((_) async => 'generated_id');

      // act
      final result = await usecase.execute(group);
      final captured =
          verify(mockGroupRepository.saveGroup(captureAny)).captured.single
              as Group;

      // assert
      expect(result, 'generated_id');
      expect(captured.id, group.id);
      expect(captured.name, group.name);
      expect(captured.ownerId, group.ownerId);
    });

    test('有効なグループに対してエラーなく完了すること', () async {
      // arrange
      final group = GroupDto(
        id: '',
        name: 'Test Group',
        ownerId: 'admin123',
        members: const [],
      );

      when(
        mockGroupRepository.saveGroup(any),
      ).thenAnswer((_) async => 'generated_id');

      // act & assert
      expect(() => usecase.execute(group), returnsNormally);
    });
  });
}
