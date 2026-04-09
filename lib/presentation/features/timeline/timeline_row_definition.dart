import 'package:flutter/material.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/timeline/dvc_point_usage_timeline_row.dart';
import 'package:memora/presentation/features/timeline/group_event_timeline_row.dart';
import 'package:memora/presentation/features/timeline/member_timeline_row.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';
import 'package:memora/presentation/features/timeline/trip_timeline_row.dart';

class TimelineRowContext {
  TimelineRowContext({
    required this.groupId,
    required Map<int, List<TripEntryDto>> tripsByYear,
    required Map<int, List<DvcPointUsageDto>> dvcPointUsagesByYear,
    required Map<int, GroupEventDto> groupEventsByYear,
    required this.buildMemberLabels,
    required this.saveGroupEvent,
  }) : tripsByYear = Map.unmodifiable(tripsByYear),
       dvcPointUsagesByYear = Map.unmodifiable(dvcPointUsagesByYear),
       groupEventsByYear = Map.unmodifiable(groupEventsByYear);

  final String groupId;
  final Map<int, List<TripEntryDto>> tripsByYear;
  final Map<int, List<DvcPointUsageDto>> dvcPointUsagesByYear;
  final Map<int, GroupEventDto> groupEventsByYear;
  final List<String> Function({
    required DateTime? birthday,
    required String? gender,
    required int targetYear,
  })
  buildMemberLabels;
  final Future<void> Function({
    required GroupEventDto? currentEvent,
    required String groupId,
    required int selectedYear,
    required String memo,
  })
  saveGroupEvent;
}

abstract class TimelineRowDefinition {
  const TimelineRowDefinition({
    required this.rowId,
    required this.fixedColumnLabel,
    required this.initialHeight,
  });

  final String rowId;
  final String fixedColumnLabel;
  final double initialHeight;

  Color? backgroundColor(BuildContext context) => null;

  Key? yearCellKey(int year) => null;

  Widget buildFixedColumn(BuildContext context, TimelineRowContext rowContext) {
    return Text(fixedColumnLabel);
  }

  VoidCallback? onFixedColumnTap({
    required BuildContext context,
    required TimelineRowContext rowContext,
  }) {
    return null;
  }

  Widget buildYearCell({
    required BuildContext context,
    required TimelineRowContext rowContext,
    required int year,
    required double rowHeight,
    required double yearColumnWidth,
  });

  VoidCallback? onYearCellTap({
    required BuildContext context,
    required TimelineRowContext rowContext,
    required int year,
  }) {
    return null;
  }
}

List<TimelineRowDefinition> buildDefaultTimelineRows({
  required GroupDto groupWithMembers,
  required TimelineLayoutConfig layoutConfig,
  void Function(String groupId, int year)? onTripManagementSelected,
  VoidCallback? onDvcPointCalculationPressed,
}) {
  return [
    TripTimelineRow(
      initialHeight: layoutConfig.dataRowHeight,
      onTripManagementSelected: onTripManagementSelected,
    ),
    GroupEventTimelineRow(initialHeight: layoutConfig.dataRowHeight),
    DvcPointUsageTimelineRow(
      initialHeight: layoutConfig.dataRowHeight,
      onDvcPointCalculationPressed: onDvcPointCalculationPressed,
    ),
    ...groupWithMembers.members.map(
      (member) => MemberTimelineRow(
        member: member,
        initialHeight: layoutConfig.dataRowHeight,
      ),
    ),
  ];
}
