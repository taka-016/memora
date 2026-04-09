import 'package:flutter/material.dart';
import 'package:memora/presentation/features/group/group_event_edit_modal.dart';
import 'package:memora/presentation/features/timeline/group_event_cell.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';

class TimelineGroupEventRow extends TimelineRowDefinition {
  const TimelineGroupEventRow({required this.initialHeight});

  @override
  final double initialHeight;

  @override
  String get fixedColumnLabel => 'イベント';

  @override
  Color get backgroundColor => Colors.lightBlue.shade50;

  @override
  Key yearCellKey(int year) => Key('group_event_cell_$year');

  @override
  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    final event = rowContext.controller.groupEventsByYear[year];
    if (event == null) {
      return const SizedBox.shrink();
    }

    return GroupEventCell(
      memo: event.memo,
      availableHeight: rowContext.rowHeight,
      availableWidth: rowContext.layoutConfig.yearColumnWidth,
    );
  }

  @override
  VoidCallback yearCellTapCallback(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    return () async {
      final currentEvent = rowContext.controller.groupEventsByYear[year];

      await showGroupEventEditModal(
        context: context,
        selectedYear: year,
        initialMemo: currentEvent?.memo ?? '',
        onSave: (memo) async {
          await rowContext.controller.saveGroupEvent(
            currentEvent: currentEvent,
            groupId: rowContext.groupWithMembers.id,
            selectedYear: year,
            memo: memo,
          );
        },
      );
    };
  }
}
