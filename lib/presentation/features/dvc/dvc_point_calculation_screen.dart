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
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

enum _DvcScreenState { loading, loaded, error }

class DvcPointCalculationScreen extends HookConsumerWidget {
  const DvcPointCalculationScreen({
    super.key,
    required this.group,
    required this.onBackPressed,
  });

  static const int _initialMonthRange = 60;
  static const int _rangeIncrement = 60;
  static const double _labelColumnWidth = 140;
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

    final calculator = useMemoized(() => const CalculateDvcPointTableUsecase());

    Future<void> loadData() async {
      try {
        state.value = _DvcScreenState.loading;
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

    final currentMonth = _monthStart(DateTime.now());
    final visibleStart = _addMonths(currentMonth, startMonthOffset.value);
    final visibleEnd = _addMonths(currentMonth, endMonthOffset.value);
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
        _monthKey(summary.yearMonth): summary,
    };

    Future<void> saveContractSettings(List<_EditableContract> editable) async {
      final contractRepository = ref.read(dvcPointContractRepositoryProvider);
      final contracts = editable
          .where((contract) => contract.isValid)
          .map((contract) => contract.toEntity(group.id))
          .toList();

      await contractRepository.deleteDvcPointContractsByGroupId(group.id);
      for (final contract in contracts) {
        await contractRepository.saveDvcPointContract(contract);
      }
      await loadData();
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
        startYearMonth: _monthStart(startYearMonth),
        endYearMonth: _monthStart(endYearMonth),
        point: point,
        memo: memo.isEmpty ? null : memo,
      );
      await limitedPointRepository.saveDvcLimitedPoint(limitedPoint);
      await loadData();
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
        usageYearMonth: _monthStart(usageYearMonth),
        usedPoint: usedPoint,
        memo: memo.isEmpty ? null : memo,
      );
      await pointUsageRepository.saveDvcPointUsage(usage);
      await loadData();
    }

    void showContractManagementDialog() {
      final editable = contractsState.value
          .map(
            (contract) => _EditableContract.fromDto(
              contract,
              expanded: contractsState.value.length == 1,
            ),
          )
          .toList();
      if (editable.isEmpty) {
        editable.add(
          _EditableContract(
            contractName: '',
            contractStartYearMonth: _monthStart(DateTime.now()),
            contractEndYearMonth: _monthStart(DateTime.now()),
            useYearStartMonth: DateTime.now().month,
            annualPointText: '',
            expanded: true,
          ),
        );
      }
      var validationError = '';

      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('契約管理'),
                content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...editable.asMap().entries.map((entry) {
                          final index = entry.key;
                          final contract = entry.value;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      contract.contractName.isEmpty
                                          ? '新しい契約'
                                          : contract.contractName,
                                    ),
                                    trailing: Icon(
                                      contract.expanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        editable[index] = contract.copyWith(
                                          expanded: !contract.expanded,
                                        );
                                      });
                                    },
                                  ),
                                  if (contract.expanded)
                                    _ContractForm(
                                      contract: contract,
                                      onChanged: (updated) {
                                        setState(() {
                                          editable[index] = updated;
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            key: const Key('dvc_contract_add_button'),
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              setState(() {
                                editable.add(
                                  _EditableContract(
                                    contractName: '',
                                    contractStartYearMonth: _monthStart(
                                      DateTime.now(),
                                    ),
                                    contractEndYearMonth: _monthStart(
                                      DateTime.now(),
                                    ),
                                    useYearStartMonth: DateTime.now().month,
                                    annualPointText: '',
                                    expanded: true,
                                  ),
                                );
                              });
                            },
                          ),
                        ),
                        if (validationError.isNotEmpty)
                          Text(
                            validationError,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final hasInvalid = editable.any((contract) {
                        return contract.contractName.trim().isEmpty ||
                            contract.annualPoint <= 0 ||
                            contract.contractEndYearMonth.isBefore(
                              contract.contractStartYearMonth,
                            );
                      });
                      if (hasInvalid) {
                        setState(() {
                          validationError = '入力内容を確認してください';
                        });
                        return;
                      }
                      Navigator.of(dialogContext).pop();
                      await saveContractSettings(editable);
                    },
                    child: const Text('更新'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    void showLimitedPointDialog() {
      var startYearMonth = _monthStart(DateTime.now());
      var endYearMonth = _monthStart(DateTime.now());
      final pointController = TextEditingController();
      final memoController = TextEditingController();
      var validationError = '';

      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('期間限定ポイント登録'),
                content: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _YearMonthSelector(
                        label: '開始年月',
                        selected: startYearMonth,
                        onSelected: (value) {
                          setState(() {
                            startYearMonth = value;
                          });
                        },
                      ),
                      _YearMonthSelector(
                        label: '終了年月',
                        selected: endYearMonth,
                        onSelected: (value) {
                          setState(() {
                            endYearMonth = value;
                          });
                        },
                      ),
                      TextField(
                        key: const Key('dvc_limited_point_field'),
                        controller: pointController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ポイント数'),
                      ),
                      TextField(
                        key: const Key('dvc_limited_memo_field'),
                        controller: memoController,
                        decoration: const InputDecoration(labelText: 'メモ'),
                      ),
                      if (validationError.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            validationError,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final point = int.tryParse(pointController.text) ?? 0;
                      if (point <= 0 || endYearMonth.isBefore(startYearMonth)) {
                        setState(() {
                          validationError = '入力内容を確認してください';
                        });
                        return;
                      }
                      Navigator.of(dialogContext).pop();
                      await saveLimitedPoint(
                        startYearMonth: startYearMonth,
                        endYearMonth: endYearMonth,
                        point: point,
                        memo: memoController.text.trim(),
                      );
                    },
                    child: const Text('登録'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    void showUsageDialog({
      required DateTime targetYearMonth,
      required int maxAvailablePoint,
    }) {
      final pointController = TextEditingController();
      final memoController = TextEditingController();
      var validationError = '';

      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('ポイント利用登録'),
                content: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_formatYearMonth(targetYearMonth)}の利用登録'),
                      TextField(
                        key: const Key('dvc_usage_point_field'),
                        controller: pointController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '利用ポイント'),
                      ),
                      TextField(
                        key: const Key('dvc_usage_memo_field'),
                        controller: memoController,
                        decoration: const InputDecoration(labelText: 'メモ'),
                      ),
                      if (validationError.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            validationError,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final usedPoint = int.tryParse(pointController.text) ?? 0;
                      if (usedPoint <= 0) {
                        setState(() {
                          validationError = '利用ポイントを入力してください';
                        });
                        return;
                      }
                      if (usedPoint > maxAvailablePoint) {
                        setState(() {
                          validationError = '利用可能ポイントを超えています';
                        });
                        return;
                      }
                      Navigator.of(dialogContext).pop();
                      await saveUsage(
                        usageYearMonth: targetYearMonth,
                        usedPoint: usedPoint,
                        memo: memoController.text.trim(),
                      );
                    },
                    child: const Text('登録'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    void showAvailableBreakdownDialog(
      DateTime month,
      List<DvcAvailablePointBreakdown> breakdowns,
    ) {
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('${_formatYearMonth(month)} 利用可能ポイント内訳'),
            content: SizedBox(
              width: 520,
              child: breakdowns.isEmpty
                  ? const Text('内訳がありません')
                  : ListView(
                      shrinkWrap: true,
                      children: breakdowns.map((breakdown) {
                        final period =
                            '${_formatYearMonth(breakdown.availableFrom)}〜${_formatYearMonth(breakdown.expireAt)}';
                        final memo =
                            breakdown.memo == null || breakdown.memo!.isEmpty
                            ? ''
                            : '\n${breakdown.memo!}';
                        return ListTile(
                          title: Text(
                            '${breakdown.sourceName}: ${breakdown.remainingPoint}pt',
                          ),
                          subtitle: Text('$period$memo'),
                        );
                      }).toList(),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          );
        },
      );
    }

    void showUsageBreakdownDialog(
      DateTime month,
      List<DvcPointUsageDto> usages,
    ) {
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('${_formatYearMonth(month)} 利用登録済ポイント内訳'),
            content: SizedBox(
              width: 520,
              child: usages.isEmpty
                  ? const Text('利用登録がありません')
                  : ListView(
                      shrinkWrap: true,
                      children: usages.map((usage) {
                        final memo = usage.memo?.isEmpty ?? true
                            ? ''
                            : usage.memo!;
                        return ListTile(
                          title: Text('${usage.usedPoint}pt'),
                          subtitle: Text(memo),
                        );
                      }).toList(),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          );
        },
      );
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('dvc_contract_management_button'),
                    icon: const Icon(Icons.assignment),
                    onPressed: showContractManagementDialog,
                  ),
                  IconButton(
                    key: const Key('dvc_limited_point_button'),
                    icon: const Icon(Icons.local_offer),
                    onPressed: showLimitedPointDialog,
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
                    style: const TextStyle(fontSize: 13),
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
            child: TextButton(
              key: const Key('dvc_show_more_past'),
              onPressed: () {
                startMonthOffset.value =
                    startMonthOffset.value - _rangeIncrement;
              },
              child: const Text(
                'さらに\n表示',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9),
              ),
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
            child: TextButton(
              key: const Key('dvc_show_more_future'),
              onPressed: () {
                endMonthOffset.value = endMonthOffset.value + _rangeIncrement;
              },
              child: const Text(
                'さらに\n表示',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9),
              ),
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
            final summary = summaryByMonthKey[_monthKey(month)];
            final availablePoint = summary?.availablePoint ?? 0;
            final breakdowns = summary?.availableBreakdowns ?? const [];
            return buildMonthCell(
              month: month,
              keyPrefix: 'dvc_available_cell_',
              text: '$availablePoint pt',
              borderColor: borderColor,
              onTap: () => showAvailableBreakdownDialog(month, breakdowns),
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
            final summary = summaryByMonthKey[_monthKey(month)];
            final usedPoint = summary?.usedPoint ?? 0;
            final usageDetails = summary?.usageDetails ?? const [];
            final availablePoint = summary?.availablePoint ?? 0;
            return buildMonthCell(
              month: month,
              keyPrefix: 'dvc_used_cell_',
              text: '$usedPoint pt',
              borderColor: borderColor,
              onTap: () => showUsageBreakdownDialog(month, usageDetails),
              footer: Align(
                alignment: Alignment.bottomCenter,
                child: IconButton(
                  key: ValueKey(
                    'dvc_add_usage_button_${month.year}_${month.month}',
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 20,
                  onPressed: () => showUsageDialog(
                    targetYearMonth: month,
                    maxAvailablePoint: availablePoint,
                  ),
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
                      label: '利用可能ポイント',
                      height: _rowHeight,
                      borderColor: borderColor,
                    ),
                    buildLabelCell(
                      label: '利用登録済ポイント',
                      height: _rowHeight,
                      borderColor: borderColor,
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    key: const Key('dvc_table_horizontal_scroll'),
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

class _YearMonthSelector extends StatelessWidget {
  const _YearMonthSelector({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selected,
              firstDate: DateTime(2000, 1),
              lastDate: DateTime(2100, 12),
            );
            if (picked == null) {
              return;
            }
            onSelected(DateTime(picked.year, picked.month));
          },
          child: Text(_formatYearMonth(selected)),
        ),
      ],
    );
  }
}

class _ContractForm extends StatelessWidget {
  const _ContractForm({required this.contract, required this.onChanged});

  final _EditableContract contract;
  final ValueChanged<_EditableContract> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: contract.contractName,
          decoration: const InputDecoration(labelText: '契約名'),
          onChanged: (value) {
            onChanged(contract.copyWith(contractName: value));
          },
        ),
        _YearMonthSelector(
          label: '契約開始年月',
          selected: contract.contractStartYearMonth,
          onSelected: (value) {
            onChanged(contract.copyWith(contractStartYearMonth: value));
          },
        ),
        _YearMonthSelector(
          label: '契約終了年月',
          selected: contract.contractEndYearMonth,
          onSelected: (value) {
            onChanged(contract.copyWith(contractEndYearMonth: value));
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('ユースイヤー開始月'),
            const SizedBox(width: 16),
            DropdownButton<int>(
              value: contract.useYearStartMonth,
              items: List.generate(
                12,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1}月'),
                ),
              ),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                onChanged(contract.copyWith(useYearStartMonth: value));
              },
            ),
          ],
        ),
        TextFormField(
          initialValue: contract.annualPointText,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '年間ポイント'),
          onChanged: (value) {
            onChanged(contract.copyWith(annualPointText: value));
          },
        ),
      ],
    );
  }
}

class _EditableContract {
  _EditableContract({
    required this.contractName,
    required this.contractStartYearMonth,
    required this.contractEndYearMonth,
    required this.useYearStartMonth,
    required this.annualPointText,
    required this.expanded,
  });

  factory _EditableContract.fromDto(
    DvcPointContractDto dto, {
    required bool expanded,
  }) {
    return _EditableContract(
      contractName: dto.contractName,
      contractStartYearMonth: _monthStart(dto.contractStartYearMonth),
      contractEndYearMonth: _monthStart(dto.contractEndYearMonth),
      useYearStartMonth: dto.useYearStartMonth,
      annualPointText: dto.annualPoint.toString(),
      expanded: expanded,
    );
  }

  final String contractName;
  final DateTime contractStartYearMonth;
  final DateTime contractEndYearMonth;
  final int useYearStartMonth;
  final String annualPointText;
  final bool expanded;

  int get annualPoint => int.tryParse(annualPointText) ?? 0;

  bool get isValid {
    return contractName.trim().isNotEmpty &&
        annualPoint > 0 &&
        !contractEndYearMonth.isBefore(contractStartYearMonth);
  }

  DvcPointContract toEntity(String groupId) {
    return DvcPointContract(
      id: '',
      groupId: groupId,
      contractName: contractName.trim(),
      contractStartYearMonth: contractStartYearMonth,
      contractEndYearMonth: contractEndYearMonth,
      useYearStartMonth: useYearStartMonth,
      annualPoint: annualPoint,
    );
  }

  _EditableContract copyWith({
    String? contractName,
    DateTime? contractStartYearMonth,
    DateTime? contractEndYearMonth,
    int? useYearStartMonth,
    String? annualPointText,
    bool? expanded,
  }) {
    return _EditableContract(
      contractName: contractName ?? this.contractName,
      contractStartYearMonth:
          contractStartYearMonth ?? this.contractStartYearMonth,
      contractEndYearMonth: contractEndYearMonth ?? this.contractEndYearMonth,
      useYearStartMonth: useYearStartMonth ?? this.useYearStartMonth,
      annualPointText: annualPointText ?? this.annualPointText,
      expanded: expanded ?? this.expanded,
    );
  }
}

List<DateTime> _buildMonthList(DateTime startYearMonth, DateTime endYearMonth) {
  final start = _monthStart(startYearMonth);
  final end = _monthStart(endYearMonth);
  if (end.isBefore(start)) {
    return const [];
  }
  final result = <DateTime>[];
  for (var month = start; !month.isAfter(end); month = _addMonths(month, 1)) {
    result.add(month);
  }
  return result;
}

DateTime _monthStart(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month);

DateTime _addMonths(DateTime dateTime, int months) {
  return DateTime(dateTime.year, dateTime.month + months);
}

String _monthKey(DateTime dateTime) => '${dateTime.year}-${dateTime.month}';

String _formatYearMonth(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  return '${dateTime.year}-$month';
}
