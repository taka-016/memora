import 'package:flutter/material.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_context.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/trip_cell.dart';

class TripTimelineRowDefinition extends TimelineRowDefinition {
  const TripTimelineRowDefinition({required this.initialHeight});

  static const rowIdValue = 'trip';

  @override
  final double initialHeight;

  @override
  String get rowId => rowIdValue;

  @override
  String get fixedColumnLabel => '旅行';

  @override
  Color? backgroundColor(BuildContext context, TimelineRowContext rowContext) {
    return Colors.lightBlue.shade50;
  }

  @override
  void onYearCellTap(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    rowContext.onTripManagementSelected?.call(rowContext.groupId, year);
  }

  @override
  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    return TripCell(
      trips: rowContext.tripsForYear(year),
      availableHeight: rowContext.rowHeight(rowId),
      availableWidth: rowContext.layoutConfig.yearColumnWidth,
    );
  }
}
