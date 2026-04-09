import 'package:flutter/material.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';
import 'package:memora/presentation/features/dvc/dvc_point_usage_detail_modal.dart';
import 'package:memora/presentation/features/timeline/timeline_overflow_cell.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';

class DvcPointUsageRow extends TimelineRowDefinition {
  const DvcPointUsageRow({
    required super.initialHeight,
    this.onDvcPointCalculationPressed,
  }) : super(rowId: 'dvc_point_usage', fixedColumnLabel: 'DVC');

  final VoidCallback? onDvcPointCalculationPressed;

  @override
  Color? backgroundColor(BuildContext context) => Colors.lightBlue.shade50;

  @override
  Key? yearCellKey(int year) => Key('dvc_point_usage_cell_$year');

  @override
  Widget buildFixedColumn(BuildContext context, TimelineRowContext rowContext) {
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
            onTap: onDvcPointCalculationPressed,
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
  VoidCallback? onFixedColumnTap({
    required BuildContext context,
    required TimelineRowContext rowContext,
  }) {
    return onDvcPointCalculationPressed;
  }

  @override
  Widget buildYearCell({
    required BuildContext context,
    required TimelineRowContext rowContext,
    required int year,
    required double rowHeight,
    required double yearColumnWidth,
  }) {
    final usages = rowContext.dvcPointUsagesByYear[year] ?? [];
    if (usages.isEmpty) {
      return const SizedBox.shrink();
    }

    return _DvcPointUsageTimelineCell(
      usages: usages,
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
      final usages = rowContext.dvcPointUsagesByYear[year] ?? [];
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

class _DvcPointUsageTimelineCell extends StatelessWidget {
  const _DvcPointUsageTimelineCell({
    required this.usages,
    required this.availableHeight,
    required this.availableWidth,
  });

  static const double _itemHeight = 32.0;

  final List<DvcPointUsageDto> usages;
  final double availableHeight;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    return TimelineOverflowCell<DvcPointUsageDto>(
      items: usages,
      availableHeight: availableHeight,
      availableWidth: availableWidth,
      itemHeight: _itemHeight,
      itemBuilder: _buildUsageItem,
    );
  }

  Widget _buildUsageItem(DvcPointUsageDto usage, TextStyle textStyle) {
    final headline =
        '${dvcFormatYearMonth(usage.usageYearMonth)}  '
        '${usage.usedPoint}pt';
    final memo = usage.memo?.trim();

    return SizedBox(
      height: _itemHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: Text(
              headline,
              style: textStyle.copyWith(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (memo != null && memo.isNotEmpty)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  memo,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
