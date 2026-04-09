import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memora/presentation/features/group/group_event_edit_modal.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';

class GroupEventRow extends TimelineRowDefinition {
  const GroupEventRow({required super.initialHeight})
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
    return () {
      final currentEvent = rowContext.groupEventsByYear[year];
      unawaited(
        showGroupEventEditModal(
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
        ),
      );
    };
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
