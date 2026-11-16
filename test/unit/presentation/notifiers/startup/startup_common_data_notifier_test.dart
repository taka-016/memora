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
    return labels.future;
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
