import 'package:flutter/material.dart';
import 'package:memora/presentation/features/dvc/dvc_point_usage_detail_modal.dart';
import 'package:memora/presentation/features/timeline/dvc_cell.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';

class TimelineDvcRow extends TimelineRowDefinition {
  const TimelineDvcRow({required this.initialHeight});

  @override
  final double initialHeight;

  @override
  String get fixedColumnLabel => 'DVC';

  @override
  Color get backgroundColor => Colors.lightBlue.shade50;

  @override
  Key yearCellKey(int year) => Key('dvc_point_usage_cell_$year');

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
            onTap: rowContext.actions.onDvcPointCalculationPressed,
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
    final usages = rowContext.controller.dvcPointUsagesByYear[year] ?? [];
    if (usages.isEmpty) {
      return const SizedBox.shrink();
    }

    return DvcCell(
      usages: usages,
      availableHeight: rowContext.rowHeight,
      availableWidth: rowContext.layoutConfig.yearColumnWidth,
    );
  }

  @override
  VoidCallback? fixedColumnTapCallback(
    BuildContext context,
    TimelineRowContext rowContext,
  ) {
    return rowContext.actions.onDvcPointCalculationPressed;
  }

  @override
  VoidCallback yearCellTapCallback(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    return () {
      final usages = rowContext.controller.dvcPointUsagesByYear[year] ?? [];
      if (usages.isEmpty) {
        return;
      }

      showDvcPointUsageDetailModal(
        context: context,
        selectedYear: year,
        usages: usages,
      );
    };
  }
}
