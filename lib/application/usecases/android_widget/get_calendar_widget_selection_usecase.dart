import 'dart:convert';

import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/calendar_group_settings_storage.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/member/get_current_member_usecase.dart';

class CalendarWidgetSelection {
  CalendarWidgetSelection({
    required this.mode,
    required this.ownerId,
    required Set<String> visibleGroupIds,
  }) : visibleGroupIds = Set.unmodifiable(visibleGroupIds);
  final AppMode mode;
  final String ownerId;
  final Set<String> visibleGroupIds;
  String get cacheScope =>
      jsonEncode([mode.name, ownerId, visibleGroupIds.toList()..sort()]);
}

class GetCalendarWidgetSelectionUsecase {
  const GetCalendarWidgetSelectionUsecase({
    required this.mode,
    required this.currentMember,
    required this.groups,
    required this.storage,
  });
  final AppMode mode;
  final GetCurrentMemberUseCase currentMember;
  final GetGroupsWithMembersUsecase groups;
  final CalendarGroupSettingsStorage storage;

  Future<CalendarWidgetSelection?> execute() async {
    final member = await currentMember.execute();
    if (member == null) return null;
    final id = mode == AppMode.online ? member.accountId : member.id;
    if (id == null) return null;
    final ownerId = '${mode.name}:$id';
    final memberships = await groups.execute(member);
    final settings = await storage.load(ownerId);
    return CalendarWidgetSelection(
      mode: mode,
      ownerId: ownerId,
      visibleGroupIds: settings
          .retainGroups(memberships.map((g) => g.id).toSet())
          .visibleGroupIds,
    );
  }
}
