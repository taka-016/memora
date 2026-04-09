import 'package:flutter/material.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_controller.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';

class TimelineRowContext {
  const TimelineRowContext({
    required this.groupWithMembers,
    required this.controller,
    required this.layoutConfig,
    required this.onTripManagementSelected,
    required this.onDvcPointCalculationPressed,
  });

  final GroupDto groupWithMembers;
  final TimelineController controller;
  final TimelineLayoutConfig layoutConfig;
  final Function(String groupId, int year)? onTripManagementSelected;
  final VoidCallback? onDvcPointCalculationPressed;

  String get groupId => groupWithMembers.id;

  double rowHeight(String rowId) {
    return controller.rowHeightByRowId(rowId);
  }

  List<TripEntryDto> tripsForYear(int year) {
    return controller.tripsByYear[year] ?? [];
  }

  List<DvcPointUsageDto> dvcPointUsagesForYear(int year) {
    return controller.dvcPointUsagesByYear[year] ?? [];
  }

  GroupEventDto? groupEventForYear(int year) {
    return controller.groupEventsByYear[year];
  }

  List<String> memberLabels({
    required GroupMemberDto member,
    required int targetYear,
  }) {
    return controller.buildMemberLabels(
      birthday: member.birthday,
      gender: member.gender,
      targetYear: targetYear,
    );
  }

  Future<void> saveGroupEvent({
    required GroupEventDto? currentEvent,
    required int selectedYear,
    required String memo,
  }) {
    return controller.saveGroupEvent(
      currentEvent: currentEvent,
      groupId: groupWithMembers.id,
      selectedYear: selectedYear,
      memo: memo,
    );
  }
}
