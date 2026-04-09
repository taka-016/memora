import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_timeline_row_settings_dto.dart';
import 'package:memora/presentation/features/timeline/rows/dvc_timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/rows/group_event_timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/rows/member_timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/rows/trip_timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';

List<TimelineRowDefinition> buildTimelineRowDefinitions({
  required GroupDto groupWithMembers,
  required GroupTimelineRowSettingsDto? rowSettings,
  required TimelineLayoutConfig layoutConfig,
}) {
  final settings =
      rowSettings?.mergeWithDefaultRows(groupWithMembers) ??
      GroupTimelineRowSettingsDto.defaultsForGroup(groupWithMembers);
  final membersById = {
    for (final member in groupWithMembers.members) member.memberId: member,
  };

  return settings.rows
      .where((setting) => setting.isVisible)
      .map((setting) {
        switch (setting.rowType) {
          case GroupTimelineRowType.trip:
            return TripTimelineRowDefinition(
              rowId: setting.rowId,
              initialHeight: layoutConfig.dataRowHeight,
            );
          case GroupTimelineRowType.groupEvent:
            return GroupEventTimelineRowDefinition(
              rowId: setting.rowId,
              initialHeight: layoutConfig.dataRowHeight,
            );
          case GroupTimelineRowType.dvc:
            return DvcTimelineRowDefinition(
              rowId: setting.rowId,
              initialHeight: layoutConfig.dataRowHeight,
            );
          case GroupTimelineRowType.member:
            final memberId = setting.targetId;
            final member = memberId == null ? null : membersById[memberId];
            if (member == null) {
              return null;
            }
            return MemberTimelineRowDefinition(
              rowId: setting.rowId,
              initialHeight: layoutConfig.dataRowHeight,
              member: member,
            );
        }
      })
      .whereType<TimelineRowDefinition>()
      .toList();
}
