import 'package:flutter/material.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_context.dart';

abstract class TimelineRowDefinition {
  const TimelineRowDefinition({
    required this.rowId,
    required this.initialHeight,
  });

  final String rowId;
  final double initialHeight;

  bool isVisible(TimelineRowContext rowContext);

  Widget buildFixedColumn(BuildContext context, TimelineRowContext rowContext);

  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  );

  VoidCallback? onFixedColumnTap(TimelineRowContext rowContext) => null;

  VoidCallback? onYearCellTap(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    return null;
  }

  Color? backgroundColor(BuildContext context, TimelineRowContext rowContext) {
    return null;
  }

  Key? cellKeyForYear(int year) => null;
}
