import 'package:flutter/material.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/features/timeline/dvc_row.dart';
import 'package:memora/presentation/features/timeline/group_event_row.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';
import 'package:memora/presentation/features/timeline/member_row.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/trip_row.dart';
import 'package:memora/presentation/notifiers/group_timeline_destination.dart';

enum TimelineRowType { trip, groupEvent, dvc, member }

const defaultTimelineRowOrder = <TimelineRowType>[
  TimelineRowType.trip,
  TimelineRowType.groupEvent,
  TimelineRowType.dvc,
  TimelineRowType.member,
];

List<TimelineRowDefinition> buildTimelineRowDefinitions({
  required GroupDto groupWithMembers,
  required ValueChanged<GroupTimelineDestination>? onDestinationSelected,
  List<TimelineRowType>? rowOrder,
}) {
  final defaultHeight = TimelineLayoutConfig.defaults.dataRowHeight;
  final effectiveRowOrder = rowOrder ?? defaultTimelineRowOrder;

  return effectiveRowOrder
      .expand(
        (rowType) => _buildRowsByType(
          rowType: rowType,
          groupWithMembers: groupWithMembers,
          defaultHeight: defaultHeight,
          onDestinationSelected: onDestinationSelected,
        ),
      )
      .toList(growable: false);
}

Iterable<TimelineRowDefinition> _buildRowsByType({
  required TimelineRowType rowType,
  required GroupDto groupWithMembers,
  required double defaultHeight,
  required ValueChanged<GroupTimelineDestination>? onDestinationSelected,
}) {
  switch (rowType) {
    case TimelineRowType.trip:
      return [
        TripRow(
          groupId: groupWithMembers.id,
          initialHeight: defaultHeight,
          onDestinationSelected: onDestinationSelected,
        ),
      ];
    case TimelineRowType.groupEvent:
      return [
        GroupEventRow(
          groupId: groupWithMembers.id,
          initialHeight: defaultHeight,
        ),
      ];
    case TimelineRowType.dvc:
      return [
        DvcRow(
          groupId: groupWithMembers.id,
          initialHeight: defaultHeight,
          onDestinationSelected: onDestinationSelected,
        ),
      ];
    case TimelineRowType.member:
      return groupWithMembers.members.map(
        (member) => MemberRow(member: member, initialHeight: defaultHeight),
      );
  }
}
