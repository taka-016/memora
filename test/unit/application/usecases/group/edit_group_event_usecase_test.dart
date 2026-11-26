import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/usecases/group/edit_group_event_usecase.dart';
import 'package:memora/domain/entities/group/group_event.dart';
import 'package:memora/domain/repositories/group/group_event_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'edit_group_event_usecase_test.mocks.dart';

@GenerateMocks([GroupEventRepository])
void main() {
  late MockGroupEventRepository repository;
  late EditGroupEventUsecase usecase;
  const original = GroupEventDto(
    id: 'event',
    groupId: 'g',
    year: 2026,
    memo: '編集前',
    version: 3,
  );
  setUp(() {
    repository = MockGroupEventRepository();
    usecase = EditGroupEventUsecase(repository);
  });

  test('既存イベントがない年の空欄保存では書き込まない', () async {
    expect(
      await usecase.execute(
        groupId: 'g',
        year: 2026,
        memo: '',
        eventAtOpen: null,
      ),
      isNull,
    );
    verifyZeroInteractions(repository);
  });

  test('既存イベントの空欄保存では編集開始時のバージョンで削除する', () async {
    expect(
      await usecase.execute(
        groupId: 'g',
        year: 2026,
        memo: '',
        eventAtOpen: original,
      ),
      isNull,
    );
    verify(repository.deleteGroupEvent('event', expectedVersion: 3)).called(1);
    verifyNoMoreInteractions(repository);
  });

  for (final existing in [null, original]) {
    test('入力があれば${existing == null ? '新規作成' : '編集開始時のバージョンで更新'}する', () async {
      when(repository.saveGroupEvent(any)).thenAnswer((_) async => 'saved');
      final result = await usecase.execute(
        groupId: 'g',
        year: 2026,
        memo: '編集後',
        eventAtOpen: existing,
      );
      expect(
        result,
        GroupEventDto(
          id: 'saved',
          groupId: 'g',
          year: 2026,
          memo: '編集後',
          version: existing?.version,
        ),
      );
      verify(
        repository.saveGroupEvent(
          GroupEvent(
            id: existing?.id ?? '',
            groupId: 'g',
            year: 2026,
            memo: '編集後',
            version: existing?.version,
          ),
        ),
      ).called(1);
      verifyNoMoreInteractions(repository);
    });
  }
}
