import 'package:flutter/material.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_dvc_row.dart';
import 'package:memora/presentation/features/timeline/timeline_group_event_row.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';
import 'package:memora/presentation/features/timeline/timeline_member_row.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/timeline_trip_row.dart';

List<TimelineRowDefinition> buildDefaultTimelineRows({
  required GroupDto groupWithMembers,
  TimelineLayoutConfig layoutConfig = TimelineLayoutConfig.defaults,
  required void Function(String groupId, int year)? onTripManagementSelected,
  required VoidCallback? onDvcPointCalculationPressed,
}) {
  final defaultHeight = layoutConfig.dataRowHeight;

  return [
    TimelineTripRow(
      groupId: groupWithMembers.id,
      initialHeight: defaultHeight,
      onTripManagementSelected: onTripManagementSelected,
    ),
    TimelineGroupEventRow(
      groupId: groupWithMembers.id,
      initialHeight: defaultHeight,
    ),
    TimelineDvcRow(
      groupId: groupWithMembers.id,
      initialHeight: defaultHeight,
      onDvcPointCalculationPressed: onDvcPointCalculationPressed,
    ),
    ...groupWithMembers.members.map(
      (member) =>
          TimelineMemberRow(member: member, initialHeight: defaultHeight),
    ),
  ];
}
