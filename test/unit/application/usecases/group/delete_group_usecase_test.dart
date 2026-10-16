import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/group/delete_group_usecase.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';

import 'delete_group_usecase_test.mocks.dart';

@GenerateMocks([GroupRepository])
void main() {
  test('指定したIDの退避をRepositoryへ委譲する', () async {
    final repository = MockGroupRepository();
    when(repository.deleteGroup('id')).thenAnswer((_) async {});

    await DeleteGroupUsecase(repository).execute('id');

    verify(repository.deleteGroup('id')).called(1);
    verifyNoMoreInteractions(repository);
  });
}
