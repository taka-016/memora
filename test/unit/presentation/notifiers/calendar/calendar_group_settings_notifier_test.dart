import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/calendar_group_settings.dart';
import 'package:memora/application/services/calendar_group_settings_storage.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/composition_root/providers/calendar_group_settings_providers.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';

import '../../../../helpers/test_exception.dart';

class _Storage implements CalendarGroupSettingsStorage {
  CalendarGroupSettings value = CalendarGroupSettings(
    visibleGroupIds: {'a', 'removed'},
    defaultGroupId: 'b',
  );
  bool failLoad = false;
  bool failSave = false;
  Completer<CalendarGroupSettings>? pending;
  @override
  Future<CalendarGroupSettings> load(String ownerId) {
    if (failLoad) throw TestException('読込失敗');
    return pending?.future ?? Future.value(value);
  }

  @override
  Future<void> save(String ownerId, CalendarGroupSettings settings) async {
    if (failSave) throw TestException('保存失敗');
    value = settings;
  }
}

void main() {
  late ProviderContainer container;
  late _Storage storage;
  var widgetUpdates = 0;
  setUp(() {
    storage = _Storage();
    widgetUpdates = 0;
    container = ProviderContainer(
      overrides: [
        calendarWidgetGroupsChangedProvider.overrideWithValue(() async {
          widgetUpdates++;
        }),
        calendarSettingsOwnerProvider.overrideWithValue('online:self'),
        calendarSettingsMemberIdProvider.overrideWithValue('self'),
        calendarGroupSettingsStorageProvider.overrideWithValue(storage),
      ],
    );
    container.listen(calendarGroupSettingsNotifierProvider, (_, _) {});
    addTearDown(container.dispose);
  });
  Future<void> flush() => container.pump();
  void groups(List<String> ids) => container
      .read(groupTimelineGroupSelectionNotifierProvider.notifier)
      .setLoadedGroups(
        memberId: 'self',
        groups: [
          for (final id in ids)
            GroupDto(id: id, ownerId: 'self', name: id, members: const []),
        ],
      );
  test('復元後の再読込は未保存でも復元された単独グループを自動選択しない', () async {
    await flush();
    storage.value = CalendarGroupSettings(hasSavedSettings: false);
    await container
        .read(calendarGroupSettingsNotifierProvider.notifier)
        .reload(afterRestore: true);
    groups(['restored']);
    await flush();
    final value = container.read(calendarGroupSettingsNotifierProvider);
    expect(value.effectiveSettings.visibleGroupIds, isEmpty);
    expect(value.effectiveSettings.defaultGroupId, isNull);
    expect(storage.value.hasSavedSettings, isFalse);
  });

  test('表示選択と有効な所属の変更でウィジェットを更新する', () async {
    groups(['a', 'b']);
    await flush();
    final before = widgetUpdates;
    await container
        .read(calendarGroupSettingsNotifierProvider.notifier)
        .setVisibleGroups({'b'});
    await flush();
    expect(widgetUpdates, greaterThan(before));
    final selected = widgetUpdates;
    groups(['a']);
    await flush();
    expect(widgetUpdates, greaterThan(selected));
  });

  for (final membershipsFirst in [true, false]) {
    test('保存設定がなく所属1件なら表示対象と既定グループを自動保存する（所属が先: $membershipsFirst）', () async {
      await flush();
      final initial = CalendarGroupSettings(hasSavedSettings: false);
      final pending = Completer<CalendarGroupSettings>();
      storage.pending = pending;
      final load = container
          .read(calendarGroupSettingsNotifierProvider.notifier)
          .reload();
      if (membershipsFirst) groups(['a']);
      pending.complete(initial);
      await load;
      if (!membershipsFirst) groups(['a']);
      await flush();
      final selected = container.read(calendarGroupSettingsNotifierProvider);
      expect(selected.effectiveSettings.visibleGroupIds, {'a'});
      expect(selected.effectiveSettings.defaultGroupId, 'a');
      expect(storage.value.hasSavedSettings, isTrue);
      expect(storage.value.visibleGroupIds, {'a'});
      storage.pending = null;
      await container
          .read(calendarGroupSettingsNotifierProvider.notifier)
          .setVisibleGroups({});
      expect(
        container
            .read(calendarGroupSettingsNotifierProvider)
            .effectiveSettings
            .defaultGroupId,
        'a',
      );
      await container
          .read(calendarGroupSettingsNotifierProvider.notifier)
          .setDefaultGroup(null);
      await container
          .read(calendarGroupSettingsNotifierProvider.notifier)
          .reload();
      expect(
        container
            .read(calendarGroupSettingsNotifierProvider)
            .effectiveSettings
            .visibleGroupIds,
        isEmpty,
      );
      expect(
        container
            .read(calendarGroupSettingsNotifierProvider)
            .effectiveSettings
            .defaultGroupId,
        isNull,
      );
    });
  }
  test('所属が複数または明示的な未選択設定がある場合は自動選択しない', () async {
    await flush();
    storage.value = CalendarGroupSettings(hasSavedSettings: false);
    groups(['a', 'b']);
    await container
        .read(calendarGroupSettingsNotifierProvider.notifier)
        .reload();
    expect(
      container
          .read(calendarGroupSettingsNotifierProvider)
          .effectiveSettings
          .visibleGroupIds,
      isEmpty,
    );
    storage.value = CalendarGroupSettings();
    await container
        .read(calendarGroupSettingsNotifierProvider.notifier)
        .reload();
    groups(['a']);
    await flush();
    expect(
      container
          .read(calendarGroupSettingsNotifierProvider)
          .effectiveSettings
          .visibleGroupIds,
      isEmpty,
    );
    expect(
      container
          .read(calendarGroupSettingsNotifierProvider)
          .effectiveSettings
          .defaultGroupId,
      isNull,
    );
  });
  test('初期選択の保存失敗では操作を待機し再取得から再試行できる', () async {
    await flush();
    storage.value = CalendarGroupSettings(hasSavedSettings: false);
    storage.failSave = true;
    groups(['a']);
    await container
        .read(calendarGroupSettingsNotifierProvider.notifier)
        .reload();
    expect(
      container.read(calendarGroupSettingsNotifierProvider).canUseSettings,
      isFalse,
    );
    expect(storage.value.visibleGroupIds, isEmpty);
    storage.failSave = false;
    await container
        .read(calendarGroupSettingsNotifierProvider.notifier)
        .reload();
    expect(
      container.read(calendarGroupSettingsNotifierProvider).canUseSettings,
      isTrue,
    );
    expect(
      container
          .read(calendarGroupSettingsNotifierProvider)
          .effectiveSettings
          .visibleGroupIds,
      {'a'},
    );
  });
  test('設定取得失敗では保存できず読み直してから操作を再開する', () async {
    storage.failLoad = true;
    await container
        .read(calendarGroupSettingsNotifierProvider.notifier)
        .reload();
    await flush();
    groups(['a', 'b']);
    expect(
      container.read(calendarGroupSettingsNotifierProvider).canUseSettings,
      isFalse,
    );
    expect(
      await container
          .read(calendarGroupSettingsNotifierProvider.notifier)
          .setVisibleGroups({'b'}),
      isFalse,
    );
    expect(storage.value.visibleGroupIds, {'a', 'removed'});
    storage.failLoad = false;
    await container
        .read(calendarGroupSettingsNotifierProvider.notifier)
        .reload();
    expect(
      container.read(calendarGroupSettingsNotifierProvider).canUseSettings,
      isTrue,
    );
  });
  test('設定の再取得が逆順で終わっても古い値へ戻さない', () async {
    await flush();
    final old = Completer<CalendarGroupSettings>();
    storage.pending = old;
    final first = container
        .read(calendarGroupSettingsNotifierProvider.notifier)
        .reload();
    storage.pending = null;
    storage.value = CalendarGroupSettings(visibleGroupIds: {'b'});
    await container
        .read(calendarGroupSettingsNotifierProvider.notifier)
        .reload();
    old.complete(CalendarGroupSettings(visibleGroupIds: {'old'}));
    await first;
    expect(
      container
          .read(calendarGroupSettingsNotifierProvider)
          .settings
          .visibleGroupIds,
      {'b'},
    );
  });
  test('所属取得成功時だけ対象を照合し既定値と表示を独立に更新する', () async {
    await flush();
    expect(
      container
          .read(calendarGroupSettingsNotifierProvider)
          .settings
          .visibleGroupIds,
      {'a', 'removed'},
    );
    groups(['a', 'b']);
    await flush();
    var state = container.read(calendarGroupSettingsNotifierProvider);
    expect(state.effectiveSettings.visibleGroupIds, {'a'});
    expect(state.effectiveSettings.defaultGroupId, 'b');
    expect(
      await container
          .read(calendarGroupSettingsNotifierProvider.notifier)
          .setDefaultGroup(null),
      isTrue,
    );
    state = container.read(calendarGroupSettingsNotifierProvider);
    expect(state.settings.visibleGroupIds, {'a', 'removed'});
    expect(state.settings.defaultGroupId, isNull);
  });
  test('保存失敗では確定済み設定を保持し再試行できる', () async {
    await flush();
    groups(['a', 'b']);
    storage.failSave = true;
    expect(
      await container
          .read(calendarGroupSettingsNotifierProvider.notifier)
          .setVisibleGroups({'b'}),
      isFalse,
    );
    expect(
      container
          .read(calendarGroupSettingsNotifierProvider)
          .settings
          .visibleGroupIds,
      {'a', 'removed'},
    );
    storage.failSave = false;
    expect(
      await container
          .read(calendarGroupSettingsNotifierProvider.notifier)
          .setVisibleGroups({'b'}),
      isTrue,
    );
    expect(
      container
          .read(calendarGroupSettingsNotifierProvider)
          .effectiveSettings
          .defaultGroupId,
      'b',
    );
  });
  test('利用者切替前の読み込み結果を反映しない', () async {
    final old = Completer<CalendarGroupSettings>();
    storage.pending = old;
    await flush();
    container.updateOverrides([
      calendarWidgetGroupsChangedProvider.overrideWithValue(() async {
        widgetUpdates++;
      }),
      calendarSettingsOwnerProvider.overrideWithValue('online:other'),
      calendarSettingsMemberIdProvider.overrideWithValue('other'),
      calendarGroupSettingsStorageProvider.overrideWithValue(storage),
    ]);
    storage.pending = null;
    await flush();
    old.complete(CalendarGroupSettings(visibleGroupIds: {'old'}));
    await flush();
    expect(
      container
          .read(calendarGroupSettingsNotifierProvider)
          .settings
          .visibleGroupIds,
      isNot(contains('old')),
    );
  });
}
