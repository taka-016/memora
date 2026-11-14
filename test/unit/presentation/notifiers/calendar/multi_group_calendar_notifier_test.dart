import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/models/calendar_group_settings.dart';
import 'package:memora/composition_root/providers/calendar_group_settings_providers.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';
import 'package:memora/presentation/notifiers/calendar/multi_group_calendar_notifier.dart';

class _Settings extends CalendarGroupSettingsNotifier {
  @override
  CalendarGroupSettingsState build() => CalendarGroupSettingsState(settings: CalendarGroupSettings(visibleGroupIds: {'a', 'b'}), groups: const [
    GroupDto(id: 'a', ownerId: 'self', name: '家族', color: '#FF0000', members: []),
    GroupDto(id: 'b', ownerId: 'self', name: '友人', color: '#0000FF', members: []),
  ], groupsReady: true, isLoading: false);
  void select(Set<String> ids) => state = state.copyWith(settings: CalendarGroupSettings(visibleGroupIds: ids));
}
class _Calendar extends CalendarNotifier {
  int loads = 0;
  @override
  CalendarState build(String groupId) => CalendarState(selectedDate: DateTime(2026, 11, 14), group: GroupDto(id: groupId, ownerId: 'self', name: groupId, members: const []));
  @override
  Future<void> load() async { loads++; }
  @override
  void selectDate(DateTime date) => state = state.copyWith(selectedDate: date);
  void receive({String error = ''}) => state = state.copyWith(loadError: error, events: [CalendarEventDto(id: 'same', groupId: groupId, labelType: 'group', title: groupId, startDateTime: DateTime(2026, 11, 14), endDateTime: DateTime(2026, 11, 15), isAllDay: true)]);
}
void main() {
  test('グループごとに取得・ラベルを区別し一部失敗と解除で他の予定を失わない', () async {
    final a = _Calendar();
    final b = _Calendar();
    final container = ProviderContainer(overrides: [
      calendarSettingsOwnerProvider.overrideWithValue('online:self'),
      calendarGroupSettingsNotifierProvider.overrideWith(_Settings.new),
      calendarNotifierProvider('a').overrideWith(() => a),
      calendarNotifierProvider('b').overrideWith(() => b),
    ]);
    addTearDown(container.dispose);
    container.listen(multiGroupCalendarNotifierProvider, (_, _) {});
    await container.pump();
    a.receive(); b.receive(error: '取得失敗');
    var state = container.read(multiGroupCalendarNotifierProvider);
    expect(state.calendar.events.map((e) => e.groupId), ['a', 'b']);
    expect(state.calendar.displayLabels.map((l) => (l.groupId, l.id)).toSet().length, 2);
    expect(state.failedGroupIds, {'b'});
    final notifier = container.read(multiGroupCalendarNotifierProvider.notifier);
    notifier.selectDate(DateTime(2026, 12, 1));
    expect(container.read(calendarNotifierProvider('a')).month, DateTime(2026, 12));
    (container.read(calendarGroupSettingsNotifierProvider.notifier) as _Settings).select({'a'});
    await container.pump();
    state = container.read(multiGroupCalendarNotifierProvider);
    expect(state.calendar.events.map((e) => e.groupId), ['a']);
    expect(a.loads, 1);
    expect(b.loads, 1);
  });
}
