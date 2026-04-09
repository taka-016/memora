import 'package:flutter/material.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/trip_cell.dart';

class TimelineTripRow extends TimelineRowDefinition {
  const TimelineTripRow({required this.initialHeight});

  @override
  final double initialHeight;

  @override
  String get fixedColumnLabel => '旅行';

  @override
  Color get backgroundColor => Colors.lightBlue.shade50;

  @override
  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    final trips = rowContext.controller.tripsByYear[year] ?? [];

    return TripCell(
      trips: trips,
      availableHeight: rowContext.rowHeight,
      availableWidth: rowContext.layoutConfig.yearColumnWidth,
    );
  }

  @override
  VoidCallback? yearCellTapCallback(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    final callback = rowContext.actions.onTripManagementSelected;
    if (callback == null) {
      return null;
    }

    return () => callback(rowContext.groupWithMembers.id, year);
  }
}
