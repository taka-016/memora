import 'package:flutter/material.dart';
import 'package:memora/presentation/features/group/group_event_edit_modal.dart';
import 'package:memora/presentation/features/timeline/group_event_cell.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_context.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_definition.dart';

class GroupEventTimelineRowDefinition extends TimelineRowDefinition {
  const GroupEventTimelineRowDefinition({
    required super.rowId,
    required super.initialHeight,
  });

  @override
  bool isVisible(TimelineRowContext rowContext) => true;

  @override
  Widget buildFixedColumn(BuildContext context, TimelineRowContext rowContext) {
    return const Text('イベント');
  }

  @override
  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    final event = rowContext.groupEventsByYear[year];
    if (event == null) {
      return const SizedBox.shrink();
    }

    return GroupEventCell(
      memo: event.memo,
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
    return () async {
      final currentEvent = rowContext.groupEventsByYear[year];
      await showGroupEventEditModal(
        context: context,
        selectedYear: year,
        initialMemo: currentEvent?.memo ?? '',
        onSave: (memo) async {
          await rowContext.saveGroupEvent(
            currentEvent: currentEvent,
            groupId: rowContext.groupWithMembers.id,
            selectedYear: year,
            memo: memo,
          );
        },
      );
    };
  }

  @override
  Color? backgroundColor(BuildContext context, TimelineRowContext rowContext) {
    return Colors.lightBlue.shade50;
  }

  @override
  Key? cellKeyForYear(int year) => Key('group_event_cell_$year');
}
