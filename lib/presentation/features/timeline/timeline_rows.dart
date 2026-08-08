import 'package:flutter/material.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/features/timeline/dvc_row.dart';
import 'package:memora/presentation/features/timeline/group_event_row.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';
import 'package:memora/presentation/features/timeline/member_row.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/trip_row.dart';

enum TimelineRowType { trip, groupEvent, dvc, member }

const defaultTimelineRowOrder = <TimelineRowType>[
  TimelineRowType.trip,
  TimelineRowType.groupEvent,
  TimelineRowType.dvc,
  TimelineRowType.member,
];

List<TimelineRowDefinition> buildTimelineRows({
  required GroupDto groupWithMembers,
  required void Function(String groupId, int year)? onTripSelected,
  required ValueChanged<String>? onDvcSelected,
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
          onTripSelected: onTripSelected,
          onDvcSelected: onDvcSelected,
        ),
      )
      .toList(growable: false);
}

Iterable<TimelineRowDefinition> _buildRowsByType({
  required TimelineRowType rowType,
  required GroupDto groupWithMembers,
  required double defaultHeight,
  required void Function(String groupId, int year)? onTripSelected,
  required ValueChanged<String>? onDvcSelected,
}) {
  switch (rowType) {
    case TimelineRowType.trip:
      return [
        TripRow(
          groupId: groupWithMembers.id,
          initialHeight: defaultHeight,
          onTripSelected: onTripSelected,
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
          onDvcSelected: onDvcSelected,
        ),
      ];
    case TimelineRowType.member:
      return groupWithMembers.members.map(
        (member) => MemberRow(member: member, initialHeight: defaultHeight),
      );
  }
}
