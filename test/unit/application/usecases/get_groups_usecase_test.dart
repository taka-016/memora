import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/get_groups_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_groups_usecase_test.mocks.dart';

@GenerateMocks([GroupRepository])
void main() {
  late GetGroupsUsecase usecase;
  late MockGroupRepository mockGroupRepository;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    usecase = GetGroupsUsecase(groupRepository: mockGroupRepository);
  });

  group('GetGroupsUsecase', () {
    test('グループが複数件取得できること', () async {
      // Arrange
      final groups = [
        Group(id: '1', name: 'グループ1', memo: 'メモ1'),
        Group(id: '2', name: 'グループ2', memo: 'メモ2'),
      ];
      when(mockGroupRepository.getGroups()).thenAnswer((_) async => groups);

      // Act
      final result = await usecase.execute();

      // Assert
      expect(result, groups);
      verify(mockGroupRepository.getGroups()).called(1);
    });

    test('グループが1件取得できること', () async {
      // Arrange
      final groups = [Group(id: '1', name: 'グループ1', memo: 'メモ1')];
      when(mockGroupRepository.getGroups()).thenAnswer((_) async => groups);

      // Act
      final result = await usecase.execute();

      // Assert
      expect(result, groups);
      expect(result.length, 1);
      verify(mockGroupRepository.getGroups()).called(1);
    });

    test('グループが0件の場合、空のリストが返されること', () async {
      // Arrange
      when(mockGroupRepository.getGroups()).thenAnswer((_) async => []);

      // Act
      final result = await usecase.execute();

      // Assert
      expect(result, []);
      verify(mockGroupRepository.getGroups()).called(1);
    });

    test('リポジトリでエラーが発生した場合、例外が再スローされること', () async {
      // Arrange
      when(mockGroupRepository.getGroups()).thenThrow(Exception('データベースエラー'));

      // Act & Assert
      expect(() async => await usecase.execute(), throwsA(isA<Exception>()));
    });
  });
}
