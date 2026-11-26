import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/queries/group/group_event_query_service.dart';
import 'package:memora/composition_root/factories/query_service_factory.dart';
import 'package:memora/composition_root/factories/repository_factory.dart';
import 'package:memora/domain/repositories/group/group_event_repository.dart';
import 'package:memora/presentation/notifiers/timeline/timeline_group_events_notifier.dart';
import 'package:memora/presentation/features/timeline/timeline_rows_refresh_provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'timeline_group_events_notifier_test.mocks.dart';

@GenerateMocks([GroupEventQueryService, GroupEventRepository])
void main() {
  const original = GroupEventDto(
    id: 'e',
    groupId: 'g',
    year: 2026,
    memo: '編集前',
    version: 3,
  );
  const other = GroupEventDto(
    id: 'other',
    groupId: 'g',
    year: 2025,
    memo: '別の年',
  );
  final provider = timelineGroupEventsProvider('g');
  late MockGroupEventQueryService query;
  late MockGroupEventRepository repository;
  late ProviderContainer container;

  setUp(() async {
    query = MockGroupEventQueryService();
    repository = MockGroupEventRepository();
    when(query.getGroupEventsByGroupId(any, orderBy: anyNamed('orderBy')))
        .thenAnswer((_) async => [original, other]);
    container = ProviderContainer(
      overrides: [
        groupEventQueryServiceProvider.overrideWithValue(query),
        groupEventRepositoryProvider.overrideWithValue(repository),
      ],
    );
    container.listen(provider, (_, _) {});
    await container.pump();
  });
  tearDown(() => container.dispose());

  test('グループごとに年別取得を共有し全行更新で再取得する', () async {
    expect(container.read(provider).eventsByYear, {
      2026: original,
      2025: other,
    });
    container.listen(timelineGroupEventsProvider('g2'), (_, _) {});
    await container.pump();
    verify(query.getGroupEventsByGroupId('g', orderBy: anyNamed('orderBy')))
        .called(1);
    verify(query.getGroupEventsByGroupId('g2', orderBy: anyNamed('orderBy')))
        .called(1);
    container.invalidate(timelineRowsRefreshProvider);
    await container.pump();
    verify(query.getGroupEventsByGroupId('g', orderBy: anyNamed('orderBy')))
        .called(1);
    verify(query.getGroupEventsByGroupId('g2', orderBy: anyNamed('orderBy')))
        .called(1);
  });

  test('保存成功を該当年だけに反映し再取得の失敗でも表示を保つ', () async {
    final saving = Completer<String>();
    when(repository.saveGroupEvent(any)).thenAnswer((_) => saving.future);
    when(query.getGroupEventsByGroupId('g', orderBy: anyNamed('orderBy')))
        .thenThrow(TestException('再取得失敗'));
    final pending = container
        .read(provider.notifier)
        .save(year: 2026, memo: '編集後', eventAtOpen: original);
    expect(container.read(provider).eventsByYear![2026], original);
    saving.complete('e');
    await pending;
    await container.pump();
    expect(container.read(provider).eventsByYear, {
      2026: original.copyWith(memo: '編集後'),
      2025: other,
    });
    expect(container.read(provider).error, isA<TestException>());
  });

  test('削除成功時は該当年を除き再取得中も他の年を保つ', () async {
    final reload = Completer<List<GroupEventDto>>();
    when(query.getGroupEventsByGroupId('g', orderBy: anyNamed('orderBy')))
        .thenAnswer((_) => reload.future);
    await container
        .read(provider.notifier)
        .save(year: 2026, memo: '', eventAtOpen: original);
    expect(container.read(provider).eventsByYear, {2025: other});
    reload.complete([other]);
    await container.pump();
    expect(container.read(provider).eventsByYear, {2025: other});
  });

  test('保存失敗時は編集前の表示を保ち編集開始時のバージョンで再試行する', () async {
    when(repository.saveGroupEvent(any)).thenThrow(TestException('保存失敗'));
    final notifier = container.read(provider.notifier);
    await expectLater(
      notifier.save(year: 2026, memo: '編集後', eventAtOpen: original),
      throwsA(isA<TestException>()),
    );
    expect(container.read(provider).eventsByYear![2026], original);
    when(repository.saveGroupEvent(any)).thenAnswer((_) async => 'e');
    await notifier.save(year: 2026, memo: '編集後', eventAtOpen: original);
    final calls = verify(repository.saveGroupEvent(captureAny)).captured;
    expect(calls.map((event) => event.version), [3, 3]);
  });

  test('保存前に開始した再取得が遅れて完了しても保存結果を戻さない', () async {
    final oldLoad = Completer<List<GroupEventDto>>();
    when(query.getGroupEventsByGroupId('g', orderBy: anyNamed('orderBy')))
        .thenAnswer((_) => oldLoad.future);
    final loading = container.read(provider.notifier).reload();
    final newLoad = Completer<List<GroupEventDto>>();
    when(query.getGroupEventsByGroupId('g', orderBy: anyNamed('orderBy')))
        .thenAnswer((_) => newLoad.future);
    when(repository.saveGroupEvent(any)).thenAnswer((_) async => 'e');
    await container
        .read(provider.notifier)
        .save(year: 2026, memo: '編集後', eventAtOpen: original);
    oldLoad.complete([original, other]);
    await loading;
    expect(container.read(provider).eventsByYear![2026]!.memo, '編集後');
    newLoad.complete([original.copyWith(memo: '再取得結果', version: 4), other]);
    await container.pump();
    expect(container.read(provider).eventsByYear![2026]!.version, 4);
  });

  test('取得済みの空データは再取得失敗後も編集可能として保持する', () async {
    when(query.getGroupEventsByGroupId('g', orderBy: anyNamed('orderBy')))
        .thenAnswer((_) async => []);
    await container.read(provider.notifier).reload();
    when(query.getGroupEventsByGroupId('g', orderBy: anyNamed('orderBy')))
        .thenThrow(TestException('取得失敗'));
    await container.read(provider.notifier).reload();
    expect(container.read(provider).eventsByYear, isEmpty);
    expect(container.read(provider).error, isA<TestException>());
  });
}
