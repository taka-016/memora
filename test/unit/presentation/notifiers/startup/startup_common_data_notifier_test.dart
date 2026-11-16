import 'package:memora/presentation/notifiers/calendar/calendar_event_input_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_mutation_coordinator.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/models/startup_common_data.dart';
import 'package:memora/application/services/startup_common_data_source.dart';
import 'package:memora/application/services/startup_common_data_storage.dart';
import 'package:memora/composition_root/providers/startup_common_data_providers.dart';
import 'package:memora/presentation/notifiers/startup/startup_common_data_notifier.dart';

import '../../../../helpers/test_exception.dart';

const oldGroup = GroupDto(id: 'g1', ownerId: 'm1', name: '保存済み', members: []);
const newGroup = GroupDto(id: 'g1', ownerId: 'm1', name: '最新', members: []);
const label = CalendarLabelDto(
  id: 'l1',
  groupId: 'g1',
  name: '旅行',
  color: '#123456',
);

class _Storage implements StartupCommonDataStorage {
  final values = <String, StartupCommonData>{};
  @override
  Future<StartupCommonData?> load(String owner) async => values[owner];
  @override
  Future<void> save(String owner, StartupCommonData data) async =>
      values[owner] = data;
}

class _Source implements StartupCommonDataSource {
  Completer<List<GroupDto>> groups = Completer();
  Completer<List<CalendarLabelDto>> labels = Completer();
  final started = Completer<void>();
  final labelsStarted = Completer<void>();
  final labelsByGroup = <String, Completer<List<CalendarLabelDto>>>{};
  int groupCalls = 0;
  int labelCalls = 0;
  @override
  Future<List<GroupDto>> loadGroups(String memberId) {
    groupCalls++;
    if (!started.isCompleted) started.complete();
    return groups.future;
  }

  @override
  Future<List<CalendarLabelDto>> loadLabels(String groupId) {
    labelCalls++;
    if (!labelsStarted.isCompleted) labelsStarted.complete();
    return labelsByGroup[groupId]?.future ?? labels.future;
  }
}

void main() {
  late _Storage storage;
  late _Source source;
  late ProviderContainer container;
  setUp(() {
    storage = _Storage();
    source = _Source();
    container = ProviderContainer(
      overrides: [
        startupCommonDataOwnerProvider.overrideWithValue('a1'),
        startupCommonDataMemberIdProvider.overrideWithValue('m1'),
        startupCommonDataSourceProvider.overrideWithValue(source),
        startupCommonDataStorageProvider.overrideWithValue(storage),
      ],
    );
  });
  tearDown(() => container.dispose());

  test('起動時にキャッシュを復元し、裏の最新取得を共有して確認済みなら再取得しない', () async {
    storage.values['a1'] = StartupCommonData(
      groups: [oldGroup],
      labels: {
        'g1': [label],
      },
    );
    container.read(startupCommonDataNotifierProvider);
    await source.started.future;
    expect(container.read(startupCommonDataNotifierProvider).data.groups, [
      oldGroup,
    ]);
    expect(
      container.read(startupCommonDataNotifierProvider).groupsConfirmed,
      isFalse,
    );
    final waiting = container
        .read(startupCommonDataNotifierProvider.notifier)
        .ensureLatest('g1');
    source.groups.complete([newGroup]);
    await container.pump();
    expect(container.read(startupCommonDataNotifierProvider).data.groups, [
      newGroup,
    ]);
    source.labels.complete([]);
    await waiting;
    await container.pump();
    await container
        .read(startupCommonDataNotifierProvider.notifier)
        .ensureLatest('g1');
    expect(source.groupCalls, 1);
    expect(source.labelCalls, 1);
    expect(storage.values['a1']!.groups, [newGroup]);
    expect(storage.values['a1']!.labels['g1'], isEmpty);
  });

  test('キャッシュの所属一覧は最新確認と色ラベルの完了を待たず共通利用できる', () async {
    storage.values['a1'] = StartupCommonData(groups: [oldGroup]);
    final notifier = container.read(startupCommonDataNotifierProvider.notifier);
    expect(await notifier.availableGroups(), [oldGroup]);
    expect(source.groupCalls, 1);
    expect(source.labelCalls, 0);
    source.groups.complete([newGroup]);
    source.labels.complete([]);
    await notifier.ensureLatest('g1');
  });

  test('明示更新中は保存時の最新確認も同じ取得を待ち新しいラベルを使う', () async {
    source.groups.complete([newGroup]);
    source.labels.complete([label]);
    final notifier = container.read(startupCommonDataNotifierProvider.notifier);
    await notifier.ensureLatest('g1');
    source.groups = Completer();
    source.labels = Completer();
    final refreshing = notifier.refresh();
    await container.pump();
    expect(
      container.read(startupCommonDataNotifierProvider).groupsConfirmed,
      isFalse,
    );
    var finished = false;
    final saving = notifier
        .ensureLatest('g1')
        .whenComplete(() => finished = true);
    await container.pump();
    expect(finished, isFalse);
    source.groups.complete([newGroup]);
    source.labels.complete([]);
    await Future.wait([refreshing, saving]);
    expect(
      container.read(startupCommonDataNotifierProvider).data.labels['g1'],
      isEmpty,
    );
    expect(source.groupCalls, 2);
    expect(source.labelCalls, 2);
  });

  test('ラベル更新後の再取得を共通状態と永続キャッシュへ反映する', () async {
    source.groups.complete([newGroup]);
    source.labels.complete([]);
    final notifier = container.read(startupCommonDataNotifierProvider.notifier);
    await notifier.ensureLatest('g1');
    source.labels = Completer()..complete([label]);
    // ウィジェット更新はこのテストの対象外。
    final coordinatorContainer = ProviderContainer(
      parent: container,
      overrides: [
        refreshSelectedCalendarWidgetCacheProvider.overrideWithValue(
          () async {},
        ),
      ],
    );
    addTearDown(coordinatorContainer.dispose);
    await coordinatorContainer
        .read(calendarMutationCoordinatorProvider)
        .labelsChanged('g1');
    expect(
      container.read(startupCommonDataNotifierProvider).data.labels['g1'],
      [label],
    );
    expect(storage.values['a1']!.labels['g1'], [label]);
  });

  test('ラベル変更前から進行中だった取得の後に再取得して追加ラベルを反映する', () async {
    source.groups.complete([newGroup]);
    final notifier = container.read(startupCommonDataNotifierProvider.notifier);
    await source.labelsStarted.future;
    final previous = source.labels;
    source.labels = Completer()..complete([label]);
    final changing = notifier.refreshLabels('g1');
    previous.complete([]);
    await changing;
    expect(
      container.read(startupCommonDataNotifierProvider).data.labels['g1'],
      [label],
    );
    expect(source.labelCalls, 2);
  });

  test('所属変更前から進行中だった取得の後に再取得して新しい所属を反映する', () async {
    final notifier = container.read(startupCommonDataNotifierProvider.notifier);
    await source.started.future;
    final previous = source.groups;
    source.groups = Completer()..complete([newGroup]);
    source.labels.complete([]);
    final changing = notifier.refreshAfterChange();
    previous.complete([oldGroup]);
    await changing;
    expect(container.read(startupCommonDataNotifierProvider).data.groups, [
      newGroup,
    ]);
    expect(source.groupCalls, 2);
  });

  test('別グループの取得状況でラベル取得失敗を消さず入力から再試行できる', () async {
    final failed = Completer<List<CalendarLabelDto>>();
    final succeeded = Completer<List<CalendarLabelDto>>();
    final pending = Completer<List<CalendarLabelDto>>();
    source.labelsByGroup.addAll({'g1': failed, 'g2': succeeded, 'g3': pending});
    source.groups.complete([
      newGroup,
      newGroup.copyWith(id: 'g2'),
      newGroup.copyWith(id: 'g3'),
    ]);
    container.read(startupCommonDataNotifierProvider);
    await source.labelsStarted.future;
    final failedInput = calendarEventInputNotifierProvider('失敗したグループ');
    final pendingInput = calendarEventInputNotifierProvider('取得中のグループ');
    container.listen(failedInput, (_, _) {});
    container.listen(pendingInput, (_, _) {});
    await container.read(failedInput.notifier).selectGroup('g1');
    await container.read(pendingInput.notifier).selectGroup('g3');
    failed.completeError(TestException('ラベル取得失敗'));
    await container.pump();
    expect(container.read(failedInput).error, isNotEmpty);
    expect(container.read(failedInput).isLoading, isFalse);
    expect(container.read(pendingInput).error, isEmpty);
    expect(container.read(pendingInput).isLoading, isTrue);
    succeeded.complete([]);
    await container.pump();
    expect(container.read(failedInput).error, isNotEmpty);
    expect(container.read(failedInput).isLoading, isFalse);
    pending.complete([]);
    await container.pump();
    expect(container.read(failedInput).error, isNotEmpty);
    source.labelsByGroup['g1'] = Completer()..complete([label]);
    await container.read(failedInput.notifier).retry();
    expect(container.read(failedInput).error, isEmpty);
    expect(container.read(failedInput).isLoading, isFalse);
    expect(container.read(failedInput).labels, [label]);
    await container.read(failedInput.notifier).validateForSave();
  });

  test('最新確認失敗後もキャッシュを残し、保存時の再試行で回復する', () async {
    storage.values['a1'] = StartupCommonData(
      groups: [oldGroup],
      labels: {
        'g1': [label],
      },
    );
    container.read(startupCommonDataNotifierProvider);
    await source.started.future;
    source.groups.completeError(TestException('通信失敗'));
    await container.pump();
    expect(container.read(startupCommonDataNotifierProvider).data.groups, [
      oldGroup,
    ]);
    source.groups = Completer()..complete([newGroup]);
    source.labels.complete([label]);
    await container
        .read(startupCommonDataNotifierProvider.notifier)
        .ensureLatest('g1');
    expect(source.groupCalls, 2);
    expect(
      container.read(startupCommonDataNotifierProvider).groupsConfirmed,
      isTrue,
    );
  });

  test('別アカウントのキャッシュと進行中の取得結果を表示しない', () async {
    storage.values['a1'] = StartupCommonData(groups: [oldGroup]);
    container.read(startupCommonDataNotifierProvider);
    await source.started.future;
    container.updateOverrides([
      startupCommonDataOwnerProvider.overrideWithValue('a2'),
      startupCommonDataMemberIdProvider.overrideWithValue('m2'),
      startupCommonDataSourceProvider.overrideWithValue(source),
      startupCommonDataStorageProvider.overrideWithValue(storage),
    ]);
    await container.pump();
    expect(
      container.read(startupCommonDataNotifierProvider).data.groups,
      isNull,
    );
    container.updateOverrides([
      startupCommonDataOwnerProvider.overrideWithValue(null),
      startupCommonDataMemberIdProvider.overrideWithValue('m2'),
      startupCommonDataSourceProvider.overrideWithValue(source),
      startupCommonDataStorageProvider.overrideWithValue(storage),
    ]);
    await container.pump();
    source.groups.complete([newGroup]);
    source.labels.complete([]);
    await container.pump();
    expect(
      container.read(startupCommonDataNotifierProvider).data.groups,
      isNull,
    );
    expect(storage.values['a2'], isNull);
  });

  test('未保存のグループやラベルは取得完了まで未取得と区別する', () async {
    container.read(startupCommonDataNotifierProvider);
    await source.started.future;
    expect(
      container.read(startupCommonDataNotifierProvider).data.groups,
      isNull,
    );
    source.groups.complete([newGroup]);
    await container.pump();
    expect(
      container
          .read(startupCommonDataNotifierProvider)
          .data
          .labels
          .containsKey('g1'),
      isFalse,
    );
    source.labels.complete([]);
    await container
        .read(startupCommonDataNotifierProvider.notifier)
        .ensureLatest('g1');
    expect(
      container.read(startupCommonDataNotifierProvider).data.labels['g1'],
      isEmpty,
    );
  });
}
