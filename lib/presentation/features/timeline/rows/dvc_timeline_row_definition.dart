import 'package:flutter/material.dart';
import 'package:memora/presentation/features/dvc/dvc_point_usage_detail_modal.dart';
import 'package:memora/presentation/features/timeline/dvc_cell.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_context.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_definition.dart';

class DvcTimelineRowDefinition extends TimelineRowDefinition {
  const DvcTimelineRowDefinition({required this.initialHeight});

  static const rowIdValue = 'dvc';

  @override
  final double initialHeight;

  @override
  String get rowId => rowIdValue;

  @override
  String get fixedColumnLabel => 'DVC';

  @override
  Color? backgroundColor(BuildContext context, TimelineRowContext rowContext) {
    return Colors.lightBlue.shade50;
  }

  @override
  Key? yearCellKey(int year) {
    return Key('dvc_point_usage_cell_$year');
  }

  @override
  void onFixedColumnTap(
    BuildContext context,
    TimelineRowContext rowContext,
  ) {
    rowContext.onDvcPointCalculationPressed?.call();
  }

  @override
  void onYearCellTap(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    final usages = rowContext.dvcPointUsagesForYear(year);

    if (usages.isEmpty) {
      return;
    }

    showDvcPointUsageDetailModal(
      context: context,
      selectedYear: year,
      usages: usages,
    );
  }

  @override
  Widget buildFixedColumn(
    BuildContext context,
    TimelineRowContext rowContext,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DVC'),
          const SizedBox(width: 8),
          InkWell(
            key: const Key('timeline_dvc_point_usage_edit_button'),
            onTap: rowContext.onDvcPointCalculationPressed,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.edit, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    final usages = rowContext.dvcPointUsagesForYear(year);

    if (usages.isEmpty) {
      return const SizedBox.shrink();
    }

    return DvcCell(
      usages: usages,
      availableHeight: rowContext.rowHeight(rowId),
      availableWidth: rowContext.layoutConfig.yearColumnWidth,
    );
  }
}
