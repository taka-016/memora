import 'package:flutter/widgets.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';

class TimelineRowContext {
  const TimelineRowContext({
    required this.groupWithMembers,
    required this.tripsByYear,
    required this.dvcPointUsagesByYear,
    required this.groupEventsByYear,
    required this.layoutConfig,
    required this.rowHeightFor,
    required this.buildMemberLabels,
    required this.saveGroupEvent,
    this.onTripManagementSelected,
    this.onDvcPointCalculationPressed,
  });

  final GroupDto groupWithMembers;
  final Map<int, List<TripEntryDto>> tripsByYear;
  final Map<int, List<DvcPointUsageDto>> dvcPointUsagesByYear;
  final Map<int, GroupEventDto> groupEventsByYear;
  final TimelineLayoutConfig layoutConfig;
  final double Function(String rowId, {required double defaultHeight})
  rowHeightFor;
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
  final Function(String groupId, int year)? onTripManagementSelected;
  final VoidCallback? onDvcPointCalculationPressed;
}
