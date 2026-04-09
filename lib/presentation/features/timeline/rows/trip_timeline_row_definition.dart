import 'package:flutter/material.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_context.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/trip_cell.dart';

class TripTimelineRowDefinition extends TimelineRowDefinition {
  const TripTimelineRowDefinition({
    required super.rowId,
    required super.initialHeight,
  });

  @override
  bool isVisible(TimelineRowContext rowContext) => true;

  @override
  Widget buildFixedColumn(BuildContext context, TimelineRowContext rowContext) {
    return const Text('旅行');
  }

  @override
  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    final trips = rowContext.tripsByYear[year] ?? [];
    return TripCell(
      trips: trips,
      availableHeight: rowContext.rowHeightFor(
        rowId,
        defaultHeight: initialHeight,
      ),
      availableWidth: rowContext.layoutConfig.yearColumnWidth,
    );
  }

  @override
  VoidCallback? onYearCellTap(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    final callback = rowContext.onTripManagementSelected;
    if (callback == null) {
      return null;
    }
    return () => callback(rowContext.groupWithMembers.id, year);
  }

  @override
  Color? backgroundColor(BuildContext context, TimelineRowContext rowContext) {
    return Colors.lightBlue.shade50;
  }
}
