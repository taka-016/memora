import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/usecases/dvc/calculate_dvc_point_table_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/presentation/features/dvc/dvc_available_breakdown_modal.dart';
import 'package:memora/presentation/features/dvc/dvc_contract_management_modal.dart';
import 'package:memora/presentation/features/dvc/dvc_limited_point_registration_modal.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';
import 'package:memora/presentation/features/dvc/dvc_usage_breakdown_modal.dart';
import 'package:memora/presentation/features/dvc/dvc_usage_registration_modal.dart';

enum _DvcScreenState { loading, loaded, error }

enum _DvcActionMenu { contractRegistration, limitedPointRegistration }

class DvcPointCalculationScreen extends HookConsumerWidget {
  const DvcPointCalculationScreen({
    super.key,
    required this.group,
    required this.onBackPressed,
  });

  static const int _initialMonthRange = 60;
  static const int _rangeIncrement = 60;
  static const double _labelColumnWidth = 70;
  static const double _monthColumnWidth = 40;
  static const double _rowHeight = 96;

  final GroupDto group;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = useState(_DvcScreenState.loading);
    final errorMessage = useState('');
    final contractsState = useState<List<DvcPointContractDto>>([]);
    final limitedPointsState = useState<List<DvcLimitedPointDto>>([]);
    final pointUsagesState = useState<List<DvcPointUsageDto>>([]);
    final startMonthOffset = useState(0);
    final endMonthOffset = useState(_initialMonthRange);
    final tableHorizontalScrollController = useScrollController();

    final calculator = useMemoized(() => const CalculateDvcPointTableUsecase());

    Future<void> loadData({bool showLoading = true}) async {
      try {
        final shouldShowLoading =
            showLoading || state.value != _DvcScreenState.loaded;
        if (shouldShowLoading) {
          state.value = _DvcScreenState.loading;
        }
        final contractQueryService = ref.read(
          dvcPointContractQueryServiceProvider,
        );
        final limitedPointQueryService = ref.read(
          dvcLimitedPointQueryServiceProvider,
        );
        final pointUsageQueryService = ref.read(
          dvcPointUsageQueryServiceProvider,
        );
        final results = await Future.wait([
          contractQueryService.getDvcPointContractsByGroupId(
            group.id,
            orderBy: [const OrderBy('contractName', descending: false)],
          ),
          limitedPointQueryService.getDvcLimitedPointsByGroupId(
            group.id,
            orderBy: [const OrderBy('startYearMonth', descending: false)],
          ),
          pointUsageQueryService.getDvcPointUsagesByGroupId(
            group.id,
            orderBy: [const OrderBy('usageYearMonth', descending: false)],
          ),
        ]);

        if (!context.mounted) {
          return;
        }

        contractsState.value = results[0] as List<DvcPointContractDto>;
        limitedPointsState.value = results[1] as List<DvcLimitedPointDto>;
        pointUsagesState.value = results[2] as List<DvcPointUsageDto>;
        state.value = _DvcScreenState.loaded;
      } catch (e, stack) {
        logger.e(
          'DvcPointCalculationScreen.loadData: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (!context.mounted) {
          return;
        }
        errorMessage.value = 'DVCポイント計算画面の読込に失敗しました';
        state.value = _DvcScreenState.error;
      }
    }

    useEffect(() {
      Future.microtask(loadData);
      return null;
    }, [group.id]);

    final currentMonth = dvcMonthStart(DateTime.now());
    final visibleStart = dvcAddMonths(currentMonth, startMonthOffset.value);
    final visibleEnd = dvcAddMonths(currentMonth, endMonthOffset.value);
    final visibleMonths = _buildMonthList(visibleStart, visibleEnd);

    final calculationResult = calculator.execute(
      contracts: contractsState.value,
      limitedPoints: limitedPointsState.value,
      pointUsages: pointUsagesState.value,
      startYearMonth: visibleStart,
      endYearMonth: visibleEnd,
    );
    final summaryByMonthKey = {
      for (final summary in calculationResult.monthlySummaries)
        dvcMonthKey(summary.yearMonth): summary,
    };

    Future<void> saveContractSettings(
      List<DvcEditableContract> editable,
    ) async {
      final contractRepository = ref.read(dvcPointContractRepositoryProvider);
      final contracts = editable
          .where((contract) => contract.isValid)
          .map((contract) => contract.toEntity(group.id))
          .toList();

      await contractRepository.deleteDvcPointContractsByGroupId(group.id);
      for (final contract in contracts) {
        await contractRepository.saveDvcPointContract(contract);
      }
      await loadData(showLoading: false);
    }

    Future<void> saveLimitedPoint({
      required DateTime startYearMonth,
      required DateTime endYearMonth,
      required int point,
      required String memo,
    }) async {
      final limitedPointRepository = ref.read(
        dvcLimitedPointRepositoryProvider,
      );
      final limitedPoint = DvcLimitedPoint(
        id: '',
        groupId: group.id,
        startYearMonth: dvcMonthStart(startYearMonth),
        endYearMonth: dvcMonthStart(endYearMonth),
        point: point,
        memo: memo.isEmpty ? null : memo,
      );
      await limitedPointRepository.saveDvcLimitedPoint(limitedPoint);
      await loadData(showLoading: false);
    }

    Future<void> saveUsage({
      required DateTime usageYearMonth,
      required int usedPoint,
      required String memo,
    }) async {
      final pointUsageRepository = ref.read(dvcPointUsageRepositoryProvider);
      final usage = DvcPointUsage(
        id: '',
        groupId: group.id,
        usageYearMonth: dvcMonthStart(usageYearMonth),
        usedPoint: usedPoint,
        memo: memo.isEmpty ? null : memo,
      );
      await pointUsageRepository.saveDvcPointUsage(usage);
      await loadData(showLoading: false);
    }

    Future<void> deleteLimitedPoint(String limitedPointId) async {
      final limitedPointRepository = ref.read(
        dvcLimitedPointRepositoryProvider,
      );
      await limitedPointRepository.deleteDvcLimitedPoint(limitedPointId);
      await loadData(showLoading: false);
    }

    Future<void> deleteUsage(String pointUsageId) async {
      final pointUsageRepository = ref.read(dvcPointUsageRepositoryProvider);
      await pointUsageRepository.deleteDvcPointUsage(pointUsageId);
      await loadData(showLoading: false);
    }

    Widget buildHeader() {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: -4,
              child: IconButton(
                key: const Key('dvc_back_button'),
                icon: const Icon(Icons.arrow_back),
                onPressed: onBackPressed,
              ),
            ),
            Center(
              child: Text(
                group.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: -4,
              child: PopupMenuButton<_DvcActionMenu>(
                key: const Key('dvc_action_menu_button'),
                icon: const Icon(Icons.more_vert),
                tooltip: '操作メニュー',
                onSelected: (action) {
                  switch (action) {
                    case _DvcActionMenu.contractRegistration:
                      unawaited(
                        showDvcContractManagementModal(
                          context: context,
                          contracts: contractsState.value,
                          onSave: saveContractSettings,
                        ),
                      );
                      break;
                    case _DvcActionMenu.limitedPointRegistration:
                      unawaited(
                        showDvcLimitedPointRegistrationModal(
                          context: context,
                          onSave: saveLimitedPoint,
                        ),
                      );
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<_DvcActionMenu>(
                    value: _DvcActionMenu.contractRegistration,
                    child: Text('契約登録'),
                  ),
                  PopupMenuItem<_DvcActionMenu>(
                    value: _DvcActionMenu.limitedPointRegistration,
                    child: Text('期間限定ポイント登録'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildLabelCell({
      required String label,
      required double height,
      required Color borderColor,
    }) {
      return Container(
        width: _labelColumnWidth,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: borderColor),
            top: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
            right: BorderSide(color: borderColor),
          ),
        ),
        child: Text(label),
      );
    }

    Widget buildMonthCell({
      required DateTime month,
      required String text,
      required Color borderColor,
      VoidCallback? onTap,
      Widget? footer,
      TextStyle? textStyle,
      String keyPrefix = 'dvc_month_cell_',
    }) {
      return Container(
        key: ValueKey('$keyPrefix${month.year}_${month.month}'),
        width: _monthColumnWidth,
        height: _rowHeight,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
            right: BorderSide(color: borderColor),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Center(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13).merge(textStyle),
                  ),
                ),
              ),
            ),
            if (footer != null) footer,
          ],
        ),
      );
    }

    Widget buildEdgeCell({required Color borderColor, Widget? child}) {
      return Container(
        width: _monthColumnWidth,
        height: _rowHeight,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
            right: BorderSide(color: borderColor),
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    }

    Widget buildYearMonthRow(Color borderColor) {
      return Row(
        children: [
          buildEdgeCell(
            borderColor: borderColor,
            child: IconButton(
              key: const Key('dvc_show_more_past'),
              icon: const Icon(Icons.arrow_left),
              iconSize: 28,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () {
                startMonthOffset.value =
                    startMonthOffset.value - _rangeIncrement;
              },
            ),
          ),
          ...visibleMonths.map(
            (month) => buildMonthCell(
              month: month,
              text: '${month.year}\n${month.month}月',
              borderColor: borderColor,
            ),
          ),
          buildEdgeCell(
            borderColor: borderColor,
            child: IconButton(
              key: const Key('dvc_show_more_future'),
              icon: const Icon(Icons.arrow_right),
              iconSize: 28,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () {
                endMonthOffset.value = endMonthOffset.value + _rangeIncrement;
              },
            ),
          ),
        ],
      );
    }

    Widget buildAvailableRow(Color borderColor) {
      return Row(
        children: [
          buildEdgeCell(borderColor: borderColor),
          ...visibleMonths.map((month) {
            final summary = summaryByMonthKey[dvcMonthKey(month)];
            final availablePoint = summary?.availablePoint ?? 0;
            final breakdowns = summary?.availableBreakdowns ?? const [];
            return buildMonthCell(
              month: month,
              keyPrefix: 'dvc_available_cell_',
              text: '$availablePoint',
              textStyle: availablePoint < 0
                  ? const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    )
                  : null,
              borderColor: borderColor,
              onTap: () {
                unawaited(
                  showDvcAvailableBreakdownModal(
                    context: context,
                    month: month,
                    breakdowns: breakdowns,
                    onDeleteLimitedPoint: deleteLimitedPoint,
                  ),
                );
              },
            );
          }),
          buildEdgeCell(borderColor: borderColor),
        ],
      );
    }

    Widget buildUsageRow(Color borderColor) {
      return Row(
        children: [
          buildEdgeCell(borderColor: borderColor),
          ...visibleMonths.map((month) {
            final summary = summaryByMonthKey[dvcMonthKey(month)];
            final usedPoint = summary?.usedPoint ?? 0;
            final usageDetails = summary?.usageDetails ?? const [];
            final availablePoint = summary?.availablePoint ?? 0;
            return buildMonthCell(
              month: month,
              keyPrefix: 'dvc_used_cell_',
              text: '$usedPoint',
              borderColor: borderColor,
              onTap: () {
                unawaited(
                  showDvcUsageBreakdownModal(
                    context: context,
                    month: month,
                    usages: usageDetails,
                    onDelete: deleteUsage,
                  ),
                );
              },
              footer: Align(
                alignment: Alignment.bottomCenter,
                child: IconButton(
                  key: ValueKey(
                    'dvc_add_usage_button_${month.year}_${month.month}',
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 20,
                  onPressed: () {
                    unawaited(
                      showDvcUsageRegistrationModal(
                        context: context,
                        targetYearMonth: month,
                        maxAvailablePoint: availablePoint,
                        onSave: saveUsage,
                      ),
                    );
                  },
                ),
              ),
            );
          }),
          buildEdgeCell(borderColor: borderColor),
        ],
      );
    }

    Widget buildTableContent() {
      final borderColor = Theme.of(context).colorScheme.outlineVariant;
      return Column(
        key: const Key('dvc_point_table'),
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    buildLabelCell(
                      label: '年月',
                      height: _rowHeight,
                      borderColor: borderColor,
                    ),
                    buildLabelCell(
                      label: '利用可能\nポイント',
                      height: _rowHeight,
                      borderColor: borderColor,
                    ),
                    buildLabelCell(
                      label: '利用\nポイント',
                      height: _rowHeight,
                      borderColor: borderColor,
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    key: const Key('dvc_table_horizontal_scroll'),
                    controller: tableHorizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: [
                        buildYearMonthRow(borderColor),
                        buildAvailableRow(borderColor),
                        buildUsageRow(borderColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget buildBody() {
      switch (state.value) {
        case _DvcScreenState.loading:
          return const Center(child: CircularProgressIndicator());
        case _DvcScreenState.error:
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(errorMessage.value),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: loadData, child: const Text('再読み込み')),
              ],
            ),
          );
        case _DvcScreenState.loaded:
          return buildTableContent();
      }
    }

    return Container(
      key: const Key('dvc_point_calculation_screen'),
      child: Column(
        children: [
          buildHeader(),
          Expanded(child: buildBody()),
        ],
      ),
    );
  }
}

List<DateTime> _buildMonthList(DateTime startYearMonth, DateTime endYearMonth) {
  final start = dvcMonthStart(startYearMonth);
  final end = dvcMonthStart(endYearMonth);
  if (end.isBefore(start)) {
    return const [];
  }
  final result = <DateTime>[];
  for (var month = start; !month.isAfter(end); month = dvcAddMonths(month, 1)) {
    result.add(month);
  }
  return result;
}
