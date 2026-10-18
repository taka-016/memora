import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/delete_member_usecase.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';

import 'delete_member_usecase_test.mocks.dart';

@GenerateMocks([MemberRepository])
void main() {
  test('取得時の期待バージョンを退避要求へ引き継ぐ', () async {
    final repository = MockMemberRepository();
    when(repository.deleteMember('id', expectedVersion: 7)).thenAnswer((_) async {});
    await DeleteMemberUsecase(repository).execute('id', expectedVersion: 7);
    verify(repository.deleteMember('id', expectedVersion: 7)).called(1);
  });

  test('指定したIDの退避をRepositoryへ委譲する', () async {
    final repository = MockMemberRepository();
    when(repository.deleteMember('id')).thenAnswer((_) async {});

    await DeleteMemberUsecase(repository).execute('id');

    verify(repository.deleteMember('id')).called(1);
    verifyNoMoreInteractions(repository);
  });
}
