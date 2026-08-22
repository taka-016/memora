import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/presentation/features/dvc/dvc_available_breakdown_modal.dart';
import 'package:memora/presentation/features/dvc/dvc_contract_management_modal.dart';
import 'package:memora/presentation/features/dvc/dvc_limited_point_registration_modal.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';
import 'package:memora/presentation/features/dvc/dvc_usage_breakdown_modal.dart';
import 'package:memora/presentation/features/dvc/dvc_usage_registration_modal.dart';
import 'package:memora/presentation/notifiers/dvc_point_calculation_notifier.dart';

enum _DvcActionMenu { contractRegistration, limitedPointRegistration }

class DvcPointCalculationScreen extends HookConsumerWidget {
  const DvcPointCalculationScreen({
    super.key,
    required this.groupId,
    required this.onBackPressed,
  });

  static const double _labelColumnWidth = 70;
  static const double _monthColumnWidth = 40;
  static const double _rowHeight = 96;

  final String groupId;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dvcPointCalculationNotifierProvider(groupId));
    final notifier = ref.read(
      dvcPointCalculationNotifierProvider(groupId).notifier,
    );
    final tableHorizontalScrollController = useScrollController();
    final isDialogOpen = useRef(false);
    final clock = ref.watch(appClockProvider);

    final visibleMonths = _buildMonthList(
      state.visibleStartYearMonth,
      state.visibleEndYearMonth,
    );
    final summaryByMonthKey = {
      for (final summary
          in state.calculationResult?.monthlySummaries ?? const [])
        dvcMonthKey(summary.yearMonth): summary,
    };

    Future<void> showDialogOnce(Future<void> Function() showDialog) async {
      if (isDialogOpen.value) return;
      isDialogOpen.value = true;
      try {
        await showDialog();
      } finally {
        isDialogOpen.value = false;
      }
    }

    Future<bool> showRejectedOperation(Future<bool> operation) async {
      final didRun = await operation;
      if (!didRun && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('別の操作が完了してから再度お試しください')));
      }
      return didRun;
    }

    Future<bool> saveContractSettings(
      List<DvcEditableContract> editable,
    ) async {
      final contracts = editable
          .where((contract) => contract.isValid)
          .map(
            (contract) => DvcPointContractDto(
              id: '',
              groupId: groupId,
              contractName: contract.contractName.trim(),
              contractStartYearMonth: contract.contractStartYearMonth,
              contractEndYearMonth: contract.contractEndYearMonth,
              useYearStartMonth: contract.useYearStartMonth,
              annualPoint: contract.annualPoint,
            ),
          )
          .toList();

      return showRejectedOperation(notifier.saveContracts(contracts));
    }

    Future<bool> saveLimitedPoint({
      required DateTime startYearMonth,
      required DateTime endYearMonth,
      required int point,
      required String memo,
    }) async {
      final limitedPoint = DvcLimitedPointDto(
        id: '',
        groupId: groupId,
        startYearMonth: dvcMonthStart(startYearMonth),
        endYearMonth: dvcMonthStart(endYearMonth),
        point: point,
        memo: memo.isEmpty ? null : memo,
      );
      return showRejectedOperation(notifier.saveLimitedPoint(limitedPoint));
    }

    Future<bool> saveUsage({
      required DateTime usageYearMonth,
      required int usedPoint,
      required String memo,
    }) async {
      final usage = DvcPointUsageDto(
        id: '',
        groupId: groupId,
        usageYearMonth: dvcMonthStart(usageYearMonth),
        usedPoint: usedPoint,
        memo: memo.isEmpty ? null : memo,
      );
      return showRejectedOperation(notifier.savePointUsage(usage));
    }

    Future<bool> deleteLimitedPoint(String limitedPointId) {
      return showRejectedOperation(notifier.deleteLimitedPoint(limitedPointId));
    }

    Future<bool> deleteUsage(String pointUsageId) {
      return showRejectedOperation(notifier.deletePointUsage(pointUsageId));
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
                state.group?.name ?? '',
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
                        showDialogOnce(
                          () => showDvcContractManagementModal(
                            context: context,
                            contracts: state.contracts,
                            onSave: saveContractSettings,
                            clock: clock,
                          ),
                        ),
                      );
                      break;
                    case _DvcActionMenu.limitedPointRegistration:
                      unawaited(
                        showDialogOnce(
                          () => showDvcLimitedPointRegistrationModal(
                            context: context,
                            onSave: saveLimitedPoint,
                            clock: clock,
                          ),
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
            ?footer,
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
                notifier.showMorePast();
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
                notifier.showMoreFuture();
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
                  showDialogOnce(
                    () => showDvcAvailableBreakdownModal(
                      context: context,
                      month: month,
                      breakdowns: breakdowns,
                      onDeleteLimitedPoint: deleteLimitedPoint,
                    ),
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
                  showDialogOnce(
                    () => showDvcUsageBreakdownModal(
                      context: context,
                      month: month,
                      usages: usageDetails,
                      onDelete: deleteUsage,
                    ),
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
                      showDialogOnce(
                        () => showDvcUsageRegistrationModal(
                          context: context,
                          targetYearMonth: month,
                          maxAvailablePoint: availablePoint,
                          onSave: saveUsage,
                        ),
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

    List<Widget> buildRetryButtons() {
      return [
        if (state.groupStatus == DvcPointDataLoadStatus.error)
          ElevatedButton(
            key: const Key('dvc_retry_group_button'),
            onPressed: notifier.retryGroup,
            child: const Text('グループを再取得'),
          ),
        if (state.contractsStatus == DvcPointDataLoadStatus.error)
          ElevatedButton(
            key: const Key('dvc_retry_contracts_button'),
            onPressed: notifier.retryContracts,
            child: const Text('契約を再取得'),
          ),
        if (state.limitedPointsStatus == DvcPointDataLoadStatus.error)
          ElevatedButton(
            key: const Key('dvc_retry_limited_points_button'),
            onPressed: notifier.retryLimitedPoints,
            child: const Text('期間限定ポイントを再取得'),
          ),
        if (state.pointUsagesStatus == DvcPointDataLoadStatus.error)
          ElevatedButton(
            key: const Key('dvc_retry_point_usages_button'),
            onPressed: notifier.retryPointUsages,
            child: const Text('利用ポイントを再取得'),
          ),
      ];
    }

    Widget buildBody() {
      if (state.isInitialLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!state.hasUsableData) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('DVCポイント計算画面の読込に失敗しました'),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: buildRetryButtons()),
            ],
          ),
        );
      }
      return Column(
        children: [
          if (state.hasLoadError)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: buildRetryButtons(),
              ),
            ),
          Expanded(child: buildTableContent()),
        ],
      );
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
