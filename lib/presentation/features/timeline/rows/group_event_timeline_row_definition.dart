import 'package:flutter/material.dart';
import 'package:memora/presentation/features/group/group_event_edit_modal.dart';
import 'package:memora/presentation/features/timeline/group_event_cell.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_context.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_definition.dart';

class GroupEventTimelineRowDefinition extends TimelineRowDefinition {
  const GroupEventTimelineRowDefinition({required this.initialHeight});

  static const rowIdValue = 'group_event';

  @override
  final double initialHeight;

  @override
  String get rowId => rowIdValue;

  @override
  String get fixedColumnLabel => 'イベント';

  @override
  Color? backgroundColor(BuildContext context, TimelineRowContext rowContext) {
    return Colors.lightBlue.shade50;
  }

  @override
  Key? yearCellKey(int year) {
    return Key('group_event_cell_$year');
  }

  @override
  Future<void> onYearCellTap(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) async {
    final currentEvent = rowContext.groupEventForYear(year);

    await showGroupEventEditModal(
      context: context,
      selectedYear: year,
      initialMemo: currentEvent?.memo ?? '',
      onSave: (memo) async {
        await rowContext.saveGroupEvent(
          currentEvent: currentEvent,
          selectedYear: year,
          memo: memo,
        );
      },
    );
  }

  @override
  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    final event = rowContext.groupEventForYear(year);
    if (event == null) {
      return const SizedBox.shrink();
    }

    return GroupEventCell(
      memo: event.memo,
      availableHeight: rowContext.rowHeight(rowId),
      availableWidth: rowContext.layoutConfig.yearColumnWidth,
    );
  }
}
