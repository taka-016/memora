import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/get_managed_groups_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/group_repository.dart';

import 'get_managed_groups_usecase_test.mocks.dart';

@GenerateMocks([GroupRepository])
void main() {
  late GetManagedGroupsUsecase usecase;
  late MockGroupRepository mockGroupRepository;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    usecase = GetManagedGroupsUsecase(mockGroupRepository);
  });

  group('GetManagedGroupsUsecase', () {
    test('should return list of groups managed by administrator', () async {
      // arrange
      const administratorId = 'admin123';
      final administratorMember = Member(
        id: administratorId,
        displayName: 'Admin User',
        email: 'admin@example.com',
        accountId: 'account123',
        administratorId: '',
      );

      final expectedGroups = [
        Group(id: 'group1', name: 'Group 1', administratorId: administratorId),
        Group(id: 'group2', name: 'Group 2', administratorId: administratorId),
      ];

      when(
        mockGroupRepository.getGroupsByAdministratorId(administratorId),
      ).thenAnswer((_) async => expectedGroups);

      // act
      final result = await usecase.execute(administratorMember);

      // assert
      expect(result, equals(expectedGroups));
      verify(mockGroupRepository.getGroupsByAdministratorId(administratorId));
    });

    test('should return empty list when no groups found', () async {
      // arrange
      const administratorId = 'admin123';
      final administratorMember = Member(
        id: administratorId,
        displayName: 'Admin User',
        email: 'admin@example.com',
        accountId: 'account123',
        administratorId: '',
      );

      when(
        mockGroupRepository.getGroupsByAdministratorId(administratorId),
      ).thenAnswer((_) async => []);

      // act
      final result = await usecase.execute(administratorMember);

      // assert
      expect(result, isEmpty);
      verify(mockGroupRepository.getGroupsByAdministratorId(administratorId));
    });
  });
}
