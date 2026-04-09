import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_context.dart';

abstract class TimelineRowDefinition {
  const TimelineRowDefinition();

  String get rowId;
  String get fixedColumnLabel;
  double get initialHeight;

  bool isVisible(TimelineRowContext context) => true;

  Color? backgroundColor(BuildContext context, TimelineRowContext rowContext) {
    return null;
  }

  Key? yearCellKey(int year) => null;

  FutureOr<void> onFixedColumnTap(
    BuildContext context,
    TimelineRowContext rowContext,
  ) {}

  FutureOr<void> onYearCellTap(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {}

  Widget buildFixedColumn(
    BuildContext context,
    TimelineRowContext rowContext,
  ) {
    return Text(fixedColumnLabel);
  }

  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  );
}
