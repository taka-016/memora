import 'package:flutter/material.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';
import 'package:memora/presentation/features/timeline/timeline_overflow_cell.dart';

class DvcCell extends StatelessWidget {
  static const double _itemHeight = 32.0;

  final List<DvcPointUsageDto> usages;
  final double availableHeight;
  final double availableWidth;

  const DvcCell({
    super.key,
    required this.usages,
    required this.availableHeight,
    required this.availableWidth,
  });

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
    final hasMemo = memo != null && memo.isNotEmpty;

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
          if (hasMemo)
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
