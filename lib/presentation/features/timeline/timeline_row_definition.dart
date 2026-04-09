import 'package:flutter/material.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';
import 'package:memora/presentation/features/dvc/dvc_point_usage_detail_modal.dart';
import 'package:memora/presentation/features/group/group_event_edit_modal.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';
import 'package:memora/presentation/features/timeline/timeline_overflow_cell.dart';

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

class TripTimelineRow extends TimelineRowDefinition {
  const TripTimelineRow({
    required super.initialHeight,
    this.onTripManagementSelected,
  }) : super(rowId: 'trip', fixedColumnLabel: '旅行');

  final void Function(String groupId, int year)? onTripManagementSelected;

  @override
  Color? backgroundColor(BuildContext context) => Colors.lightBlue.shade50;

  @override
  Widget buildYearCell({
    required BuildContext context,
    required TimelineRowContext rowContext,
    required int year,
    required double rowHeight,
    required double yearColumnWidth,
  }) {
    final trips = rowContext.tripsByYear[year] ?? [];
    return _TripTimelineCell(
      trips: trips,
      availableHeight: rowHeight,
      availableWidth: yearColumnWidth,
    );
  }

  @override
  VoidCallback? onYearCellTap({
    required BuildContext context,
    required TimelineRowContext rowContext,
    required int year,
  }) {
    if (onTripManagementSelected == null) {
      return null;
    }
    return () => onTripManagementSelected!(rowContext.groupId, year);
  }
}

class GroupEventTimelineRow extends TimelineRowDefinition {
  const GroupEventTimelineRow({required super.initialHeight})
    : super(rowId: 'group_event', fixedColumnLabel: 'イベント');

  @override
  Color? backgroundColor(BuildContext context) => Colors.lightBlue.shade50;

  @override
  Key? yearCellKey(int year) => Key('group_event_cell_$year');

  @override
  Widget buildYearCell({
    required BuildContext context,
    required TimelineRowContext rowContext,
    required int year,
    required double rowHeight,
    required double yearColumnWidth,
  }) {
    final event = rowContext.groupEventsByYear[year];
    if (event == null) {
      return const SizedBox.shrink();
    }

    return _GroupEventTimelineCell(
      memo: event.memo,
      availableHeight: rowHeight,
      availableWidth: yearColumnWidth,
    );
  }

  @override
  VoidCallback onYearCellTap({
    required BuildContext context,
    required TimelineRowContext rowContext,
    required int year,
  }) {
    return () async {
      final currentEvent = rowContext.groupEventsByYear[year];
      await showGroupEventEditModal(
        context: context,
        selectedYear: year,
        initialMemo: currentEvent?.memo ?? '',
        onSave: (memo) async {
          await rowContext.saveGroupEvent(
            currentEvent: currentEvent,
            groupId: rowContext.groupId,
            selectedYear: year,
            memo: memo,
          );
        },
      );
    };
  }
}

class DvcPointUsageTimelineRow extends TimelineRowDefinition {
  const DvcPointUsageTimelineRow({
    required super.initialHeight,
    this.onDvcPointCalculationPressed,
  }) : super(rowId: 'dvc_point_usage', fixedColumnLabel: 'DVC');

  final VoidCallback? onDvcPointCalculationPressed;

  @override
  Color? backgroundColor(BuildContext context) => Colors.lightBlue.shade50;

  @override
  Key? yearCellKey(int year) => Key('dvc_point_usage_cell_$year');

  @override
  Widget buildFixedColumn(BuildContext context, TimelineRowContext rowContext) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DVC'),
          const SizedBox(width: 8),
          InkWell(
            key: const Key('timeline_dvc_point_usage_edit_button'),
            onTap: onDvcPointCalculationPressed,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.edit, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  VoidCallback? onFixedColumnTap({
    required BuildContext context,
    required TimelineRowContext rowContext,
  }) {
    return onDvcPointCalculationPressed;
  }

  @override
  Widget buildYearCell({
    required BuildContext context,
    required TimelineRowContext rowContext,
    required int year,
    required double rowHeight,
    required double yearColumnWidth,
  }) {
    final usages = rowContext.dvcPointUsagesByYear[year] ?? [];
    if (usages.isEmpty) {
      return const SizedBox.shrink();
    }

    return _DvcPointUsageTimelineCell(
      usages: usages,
      availableHeight: rowHeight,
      availableWidth: yearColumnWidth,
    );
  }

  @override
  VoidCallback onYearCellTap({
    required BuildContext context,
    required TimelineRowContext rowContext,
    required int year,
  }) {
    return () {
      final usages = rowContext.dvcPointUsagesByYear[year] ?? [];
      if (usages.isEmpty) {
        return;
      }

      showDvcPointUsageDetailModal(
        context: context,
        selectedYear: year,
        usages: usages,
      );
    };
  }
}

class MemberTimelineRow extends TimelineRowDefinition {
  MemberTimelineRow({required this.member, required super.initialHeight})
    : super(
        rowId: 'member_${member.memberId}',
        fixedColumnLabel: member.displayName,
      );

  final GroupMemberDto member;

  @override
  Widget buildYearCell({
    required BuildContext context,
    required TimelineRowContext rowContext,
    required int year,
    required double rowHeight,
    required double yearColumnWidth,
  }) {
    final lines = rowContext.buildMemberLabels(
      birthday: member.birthday,
      gender: member.gender,
      targetYear: year,
    );

    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Text(lines.join('\n')),
    );
  }
}

class _TripTimelineCell extends StatelessWidget {
  const _TripTimelineCell({
    required this.trips,
    required this.availableHeight,
    required this.availableWidth,
  });

  static const double _itemHeight = 32.0;

  final List<TripEntryDto> trips;
  final double availableHeight;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    return TimelineOverflowCell<TripEntryDto>(
      items: trips,
      availableHeight: availableHeight,
      availableWidth: availableWidth,
      itemHeight: _itemHeight,
      itemBuilder: _buildTripItem,
    );
  }

  Widget _buildTripItem(TripEntryDto trip, TextStyle textStyle) {
    final formattedDate = _formatTripDate(trip);

    return SizedBox(
      height: _itemHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: Text(
              formattedDate,
              style: textStyle.copyWith(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                trip.tripName ?? '旅行名未設定',
                style: textStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTripDate(TripEntryDto trip) {
    final startDate = trip.tripStartDate;
    if (startDate == null) {
      return '${trip.tripYear}年 (期間未設定)';
    }
    final month = startDate.month.toString().padLeft(2, '0');
    final day = startDate.day.toString().padLeft(2, '0');
    return '${startDate.year}/$month/$day';
  }
}

class _GroupEventTimelineCell extends StatelessWidget {
  const _GroupEventTimelineCell({
    required this.memo,
    required this.availableHeight,
    required this.availableWidth,
  });

  final String memo;
  final double availableHeight;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final trimmedMemo = memo.trim();
    if (trimmedMemo.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxLines = (availableHeight / 20).floor().clamp(1, 20);

    return SizedBox(
      width: availableWidth,
      height: availableHeight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          trimmedMemo,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _DvcPointUsageTimelineCell extends StatelessWidget {
  const _DvcPointUsageTimelineCell({
    required this.usages,
    required this.availableHeight,
    required this.availableWidth,
  });

  static const double _itemHeight = 32.0;

  final List<DvcPointUsageDto> usages;
  final double availableHeight;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    return TimelineOverflowCell<DvcPointUsageDto>(
      items: usages,
      availableHeight: availableHeight,
      availableWidth: availableWidth,
      itemHeight: _itemHeight,
      itemBuilder: _buildUsageItem,
    );
  }

  Widget _buildUsageItem(DvcPointUsageDto usage, TextStyle textStyle) {
    final headline =
        '${dvcFormatYearMonth(usage.usageYearMonth)}  '
        '${usage.usedPoint}pt';
    final memo = usage.memo?.trim();

    return SizedBox(
      height: _itemHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: Text(
              headline,
              style: textStyle.copyWith(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (memo != null && memo.isNotEmpty)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  memo,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
