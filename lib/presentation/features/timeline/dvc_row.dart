import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_usages_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/features/dvc/dvc_point_usage_detail_modal.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/timeline_overflow_cell.dart';

class DvcRow extends TimelineRowDefinition {
  const DvcRow({
    required this.groupId,
    required this.initialHeight,
    required this.onDvcPointCalculationPressed,
  });

  final String groupId;

  @override
  final double initialHeight;
  final VoidCallback? onDvcPointCalculationPressed;

  @override
  String get fixedColumnLabel => 'DVC';

  @override
  Color get backgroundColor => Colors.lightBlue.shade50;

  @override
  Key yearCellKey(int year) => Key('dvc_point_usage_cell_$year');

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
  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    return _DvcYearCell(
      groupId: groupId,
      year: year,
      refreshKey: rowContext.controller.refreshKey,
      availableHeight: rowContext.rowHeight,
      availableWidth: rowContext.layoutConfig.yearColumnWidth,
    );
  }

  @override
  VoidCallback? fixedColumnTapCallback(
    BuildContext context,
    TimelineRowContext rowContext,
  ) {
    return onDvcPointCalculationPressed;
  }
}

final _dvcPointUsagesByYearProvider = FutureProvider.autoDispose
    .family<Map<int, List<DvcPointUsageDto>>, _DvcPointUsagesQuery>((
      ref,
      query,
    ) async {
      try {
        final getDvcPointUsagesUsecase = ref.watch(
          getDvcPointUsagesUsecaseProvider,
        );
        final usages = await getDvcPointUsagesUsecase.execute(query.groupId);
        return _groupDvcPointUsagesByYear(usages);
      } catch (e, stack) {
        logger.e(
          'DvcRow.loadDvcPointUsages: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        return {};
      }
    });

class _DvcYearCell extends ConsumerWidget {
  const _DvcYearCell({
    required this.groupId,
    required this.year,
    required this.refreshKey,
    required this.availableHeight,
    required this.availableWidth,
  });

  final String groupId;
  final int year;
  final int refreshKey;
  final double availableHeight;
  final double availableWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usages =
        ref
            .watch(
              _dvcPointUsagesByYearProvider(
                _DvcPointUsagesQuery(groupId: groupId, refreshKey: refreshKey),
              ),
            )
            .valueOrNull?[year] ??
        const [];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: usages.isEmpty
          ? null
          : () {
              showDvcPointUsageDetailModal(
                context: context,
                selectedYear: year,
                usages: usages,
              );
            },
      child: usages.isEmpty
          ? const SizedBox.expand()
          : DvcCell(
              usages: usages,
              availableHeight: availableHeight,
              availableWidth: availableWidth,
            ),
    );
  }
}

class _DvcPointUsagesQuery {
  const _DvcPointUsagesQuery({required this.groupId, required this.refreshKey});

  final String groupId;
  final int refreshKey;

  @override
  bool operator ==(Object other) {
    return other is _DvcPointUsagesQuery &&
        other.groupId == groupId &&
        other.refreshKey == refreshKey;
  }

  @override
  int get hashCode => Object.hash(groupId, refreshKey);
}

Map<int, List<DvcPointUsageDto>> _groupDvcPointUsagesByYear(
  List<DvcPointUsageDto> usages,
) {
  final grouped = <int, List<DvcPointUsageDto>>{};
  for (final usage in usages) {
    grouped.putIfAbsent(usage.usageYearMonth.year, () => []).add(usage);
  }

  for (final entry in grouped.entries) {
    entry.value.sort((a, b) {
      final comparedMonth = a.usageYearMonth.compareTo(b.usageYearMonth);
      if (comparedMonth != 0) {
        return comparedMonth;
      }
      return a.id.compareTo(b.id);
    });
  }

  return grouped;
}

class DvcCell extends StatelessWidget {
  const DvcCell({
    super.key,
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
