import 'dart:convert';

import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/services/calendar_group_settings_storage.dart';
import 'package:memora/application/usecases/member/get_current_member_usecase.dart';

class CalendarWidgetSelection {
  CalendarWidgetSelection({
    required this.mode,
    required this.ownerId,
    required List<GroupDto> visibleGroups,
  }) : visibleGroups = List.unmodifiable(visibleGroups);
  final AppMode mode;
  final String ownerId;
  final List<GroupDto> visibleGroups;
  String get cacheScope =>
      encodeScope(mode, ownerId, visibleGroups.map((group) => group.id));

  static String encodeScope(
    AppMode mode,
    String? ownerId,
    Iterable<String> visibleGroupIds,
  ) => jsonEncode([mode.name, ownerId, visibleGroupIds.toList()..sort()]);
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
  final GroupQueryService groups;
  final CalendarGroupSettingsStorage storage;

  Future<CalendarWidgetSelection?> execute() async {
    final member = await currentMember.execute();
    if (member == null) return null;
    final ownerId = _ownerId(member);
    if (ownerId == null) return null;
    final memberships = await groups.getGroupsWithMembersByMemberId(member.id);
    final settings = await storage.load(ownerId);
    return CalendarWidgetSelection(
      mode: mode,
      ownerId: ownerId,
      visibleGroups: [
        for (final group in memberships)
          if (settings.visibleGroupIds.contains(group.id)) group,
      ],
    );
  }

  Future<String?> loadCurrentScope() async {
    final member = await currentMember.execute();
    if (member == null) return null;
    final ownerId = _ownerId(member);
    if (ownerId == null) return null;
    final groupIds = await groups.getGroupIdsByMemberId(member.id);
    final settings = await storage.load(ownerId);
    return CalendarWidgetSelection.encodeScope(
      mode,
      ownerId,
      settings.visibleGroupIds.intersection(groupIds),
    );
  }

  String? _ownerId(MemberDto member) {
    final id = mode == AppMode.online ? member.accountId : member.id;
    return id == null ? null : '${mode.name}:$id';
  }
}
