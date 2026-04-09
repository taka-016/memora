import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_dvc_row.dart';
import 'package:memora/presentation/features/timeline/timeline_group_event_row.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';
import 'package:memora/presentation/features/timeline/timeline_member_row.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/timeline_trip_row.dart';

List<TimelineRowDefinition> buildDefaultTimelineRows({
  required GroupDto groupWithMembers,
  required TimelineLayoutConfig layoutConfig,
}) {
  final defaultHeight = layoutConfig.dataRowHeight;

  return [
    TimelineTripRow(initialHeight: defaultHeight),
    TimelineGroupEventRow(initialHeight: defaultHeight),
    TimelineDvcRow(initialHeight: defaultHeight),
    ...groupWithMembers.members.map(
      (member) =>
          TimelineMemberRow(member: member, initialHeight: defaultHeight),
    ),
  ];
}
