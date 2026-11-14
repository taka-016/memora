import 'package:memora/application/models/calendar_group_settings.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';

class TestCalendarGroupSettingsNotifier extends CalendarGroupSettingsNotifier {
  TestCalendarGroupSettingsNotifier({
    this.visible = const {'g1'},
    this.defaultGroupId = 'g1',
    this.groups = const [
      GroupDto(id: 'g1', ownerId: 'owner', name: '家族', members: []),
      GroupDto(id: 'g2', ownerId: 'owner', name: '友人', members: []),
    ],
  });
  final Set<String> visible;
  final String? defaultGroupId;
  final List<GroupDto> groups;
  @override
  CalendarGroupSettingsState build() => CalendarGroupSettingsState(
    settings: CalendarGroupSettings(
      visibleGroupIds: visible,
      defaultGroupId: defaultGroupId,
    ),
    groups: groups,
    groupsReady: true,
    isLoading: false,
  );
  @override
  Future<bool> setVisibleGroups(Set<String> ids) async {
    state = state.copyWith(
      settings: CalendarGroupSettings(
        visibleGroupIds: ids,
        defaultGroupId: state.settings.defaultGroupId,
      ),
    );
    return true;
  }

  @override
  Future<bool> setDefaultGroup(String? id) async {
    state = state.copyWith(
      settings: CalendarGroupSettings(
        visibleGroupIds: state.settings.visibleGroupIds,
        defaultGroupId: id,
      ),
    );
    return true;
  }
}
