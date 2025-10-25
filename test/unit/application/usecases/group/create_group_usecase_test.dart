import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
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
      final group = Group(id: '', name: 'Test Group', ownerId: 'admin123');

      when(
        mockGroupRepository.saveGroup(group),
      ).thenAnswer((_) async => 'generated_id');

      // act
      final result = await usecase.execute(group);

      // assert
      expect(result, 'generated_id');
      verify(mockGroupRepository.saveGroup(group));
    });

    test('有効なグループに対してエラーなく完了すること', () async {
      // arrange
      final group = Group(id: '', name: 'Test Group', ownerId: 'admin123');

      when(
        mockGroupRepository.saveGroup(group),
      ).thenAnswer((_) async => 'generated_id');

      // act & assert
      expect(() => usecase.execute(group), returnsNormally);
    });
  });
}
