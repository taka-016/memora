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
  CalendarGroupSettings value = CalendarGroupSettings(visibleGroupIds: {'a', 'removed'}, defaultGroupId: 'b');
  bool failSave = false;
  Completer<CalendarGroupSettings>? pending;
  @override
  Future<CalendarGroupSettings> load(String ownerId) => pending?.future ?? Future.value(value);
  @override
  Future<void> save(String ownerId, CalendarGroupSettings settings) async {
    if (failSave) throw TestException('保存失敗');
    value = settings;
  }
}
void main() {
  late ProviderContainer container;
  late _Storage storage;
  setUp(() {
    storage = _Storage();
    container = ProviderContainer(overrides: [
      calendarSettingsOwnerProvider.overrideWithValue('online:self'),
      calendarSettingsMemberIdProvider.overrideWithValue('self'),
      calendarGroupSettingsStorageProvider.overrideWithValue(storage),
    ]);
    container.listen(calendarGroupSettingsNotifierProvider, (_, _) {});
    addTearDown(container.dispose);
  });
  Future<void> flush() => container.pump();
  void groups(List<String> ids) => container.read(groupTimelineGroupSelectionNotifierProvider.notifier).setLoadedGroups(
    memberId: 'self', groups: [for (final id in ids) GroupDto(id: id, ownerId: 'self', name: id, members: const [])],
  );
  test('所属取得成功時だけ対象を照合し既定値と表示を独立に更新する', () async {
    await flush();
    expect(container.read(calendarGroupSettingsNotifierProvider).settings.visibleGroupIds, {'a', 'removed'});
    groups(['a', 'b']);
    await flush();
    var state = container.read(calendarGroupSettingsNotifierProvider);
    expect(state.effectiveSettings.visibleGroupIds, {'a'});
    expect(state.effectiveSettings.defaultGroupId, 'b');
    expect(await container.read(calendarGroupSettingsNotifierProvider.notifier).setDefaultGroup(null), isTrue);
    state = container.read(calendarGroupSettingsNotifierProvider);
    expect(state.settings.visibleGroupIds, {'a', 'removed'});
    expect(state.settings.defaultGroupId, isNull);
  });
  test('保存失敗では確定済み設定を保持し再試行できる', () async {
    await flush();
    groups(['a', 'b']);
    storage.failSave = true;
    expect(await container.read(calendarGroupSettingsNotifierProvider.notifier).setVisibleGroups({'b'}), isFalse);
    expect(container.read(calendarGroupSettingsNotifierProvider).settings.visibleGroupIds, {'a', 'removed'});
    storage.failSave = false;
    expect(await container.read(calendarGroupSettingsNotifierProvider.notifier).setVisibleGroups({'b'}), isTrue);
    expect(container.read(calendarGroupSettingsNotifierProvider).effectiveSettings.defaultGroupId, 'b');
  });
  test('利用者切替前の読み込み結果を反映しない', () async {
    final old = Completer<CalendarGroupSettings>();
    storage.pending = old;
    await flush();
    container.updateOverrides([
      calendarSettingsOwnerProvider.overrideWithValue('online:other'),
      calendarSettingsMemberIdProvider.overrideWithValue('other'),
      calendarGroupSettingsStorageProvider.overrideWithValue(storage),
    ]);
    storage.pending = null;
    await flush();
    old.complete(CalendarGroupSettings(visibleGroupIds: {'old'}));
    await flush();
    expect(container.read(calendarGroupSettingsNotifierProvider).settings.visibleGroupIds, isNot(contains('old')));
  });
}
