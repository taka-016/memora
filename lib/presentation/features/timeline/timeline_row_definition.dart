import 'package:flutter/material.dart';
import 'package:memora/presentation/features/timeline/group_timeline_destination_page_definition.dart';
import 'package:memora/presentation/features/timeline/timeline_controller.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';

class TimelineRowContext {
  const TimelineRowContext({
    required this.controller,
    required this.rowIndex,
    required this.rowHeight,
    required this.layoutConfig,
  });

  final TimelineController controller;
  final int rowIndex;
  final double rowHeight;
  final TimelineLayoutConfig layoutConfig;
}

abstract class TimelineRowDefinition {
  const TimelineRowDefinition();

  String get fixedColumnLabel;
  double get initialHeight;
  Color? get backgroundColor;
  Iterable<GroupTimelineDestinationPageDefinition>
  get destinationPageDefinitions => const [];

  Key? yearCellKey(int year) => null;

  Widget buildFixedColumn(BuildContext context, TimelineRowContext rowContext) {
    return Text(fixedColumnLabel);
  }

  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  );

  VoidCallback? fixedColumnTapCallback(
    BuildContext context,
    TimelineRowContext rowContext,
  ) {
    return null;
  }

  VoidCallback? yearCellTapCallback(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    return null;
  }
}
