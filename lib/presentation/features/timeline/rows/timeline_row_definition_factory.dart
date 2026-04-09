import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/features/timeline/rows/dvc_timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/rows/group_event_timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/rows/member_timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/rows/trip_timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';

List<TimelineRowDefinition> buildDefaultTimelineRowDefinitions(
  GroupDto groupWithMembers, {
  TimelineLayoutConfig layoutConfig = TimelineLayoutConfig.defaults,
}) {
  return [
    TripTimelineRowDefinition(initialHeight: layoutConfig.dataRowHeight),
    GroupEventTimelineRowDefinition(initialHeight: layoutConfig.dataRowHeight),
    DvcTimelineRowDefinition(initialHeight: layoutConfig.dataRowHeight),
    ...groupWithMembers.members.map(
      (member) => MemberTimelineRowDefinition(
        member: member,
        initialHeight: layoutConfig.dataRowHeight,
      ),
    ),
  ];
}
