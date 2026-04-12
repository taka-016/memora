import 'package:flutter/material.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/features/timeline/dvc_row.dart';
import 'package:memora/presentation/features/timeline/group_event_row.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';
import 'package:memora/presentation/features/timeline/member_row.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/trip_row.dart';
import 'package:memora/presentation/notifiers/group_timeline_destination.dart';

List<TimelineRowDefinition> buildDefaultTimelineRows({
  required GroupDto groupWithMembers,
  required ValueChanged<GroupTimelineDestination>? onDestinationSelected,
}) {
  final defaultHeight = TimelineLayoutConfig.defaults.dataRowHeight;

  return [
    TripRow(
      groupId: groupWithMembers.id,
      initialHeight: defaultHeight,
      onDestinationSelected: onDestinationSelected,
    ),
    GroupEventRow(groupId: groupWithMembers.id, initialHeight: defaultHeight),
    DvcRow(
      groupId: groupWithMembers.id,
      initialHeight: defaultHeight,
      onDestinationSelected: onDestinationSelected,
    ),
    ...groupWithMembers.members.map(
      (member) => MemberRow(member: member, initialHeight: defaultHeight),
    ),
  ];
}
