import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/usecases/dvc/calculate_dvc_point_table_usecase.dart';
import 'package:memora/application/usecases/dvc/create_dvc_limited_point_usecase.dart';
import 'package:memora/application/usecases/dvc/create_dvc_point_contract_usecase.dart';
import 'package:memora/application/usecases/dvc/create_dvc_point_usage_usecase.dart';
import 'package:memora/application/usecases/dvc/get_dvc_limited_points_usecase.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_contracts_usecase.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_usages_usecase.dart';

class DvcPointCalculationScreen extends HookConsumerWidget {
  const DvcPointCalculationScreen({
    required this.group,
    required this.onBackPressed,
    super.key,
  });

  final GroupDto group;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calculateDvcPointTableUsecase = useMemoized(
      CalculateDvcPointTableUsecase.new,
    );

    final isLoading = useState(true);
    final errorMessage = useState<String?>(null);

    final contracts = useState<List<DvcPointContractDto>>([]);
    final usages = useState<List<DvcPointUsageDto>>([]);
    final limitedPoints = useState<List<DvcLimitedPointDto>>([]);
    final monthlySummaries = useState<List<DvcPointMonthlySummaryDto>>([]);

    final contractNameController = useTextEditingController();
    final useYearStartMonthController = useTextEditingController(text: '10');
    final annualPointController = useTextEditingController();

    final usageMonthController = useTextEditingController(
      text: _formatYearMonth(DateTime.now()),
    );
    final usagePointController = useTextEditingController();
    final usageMemoController = useTextEditingController();

    final limitedStartMonthController = useTextEditingController(
      text: _formatYearMonth(DateTime.now()),
    );
    final limitedEndMonthController = useTextEditingController(
      text: _formatYearMonth(_addMonths(DateTime.now(), 1)),
    );
    final limitedPointController = useTextEditingController();
    final limitedMemoController = useTextEditingController();

    Future<void> loadData() async {
      isLoading.value = true;
      errorMessage.value = null;

      try {
        final getDvcPointContractsUsecase = ref.read(
          getDvcPointContractsUsecaseProvider,
        );
        final getDvcPointUsagesUsecase = ref.read(
          getDvcPointUsagesUsecaseProvider,
        );
        final getDvcLimitedPointsUsecase = ref.read(
          getDvcLimitedPointsUsecaseProvider,
        );

        final fetchedContracts = await getDvcPointContractsUsecase.execute(
          group.id,
        );
        final fetchedUsages = await getDvcPointUsagesUsecase.execute(group.id);
        final fetchedLimitedPoints = await getDvcLimitedPointsUsecase.execute(
          group.id,
        );

        final targetMonths = _buildTargetMonths(
          contracts: fetchedContracts,
          usages: fetchedUsages,
          limitedPoints: fetchedLimitedPoints,
        );

        final summaries = calculateDvcPointTableUsecase.execute(
          contracts: fetchedContracts,
          usages: fetchedUsages,
          limitedPoints: fetchedLimitedPoints,
          targetMonths: targetMonths,
        );

        contracts.value = fetchedContracts;
        usages.value = fetchedUsages;
        limitedPoints.value = fetchedLimitedPoints;
        monthlySummaries.value = summaries;
      } catch (_) {
        errorMessage.value = 'DVCポイントデータの読み込みに失敗しました。';
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      Future.microtask(loadData);
      return null;
    }, const []);

    Future<void> showMessage(String message) async {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> handleCreateContract() async {
      try {
        final contractName = contractNameController.text.trim();
        final useYearStartMonth = int.tryParse(
          useYearStartMonthController.text.trim(),
        );
        final annualPoint = int.tryParse(annualPointController.text.trim());

        if (contractName.isEmpty ||
            useYearStartMonth == null ||
            useYearStartMonth < 1 ||
            useYearStartMonth > 12 ||
            annualPoint == null ||
            annualPoint <= 0) {
          await showMessage('契約名・ユースイヤー開始月・付与ポイント数を正しく入力してください。');
          return;
        }

        final createDvcPointContractUsecase = ref.read(
          createDvcPointContractUsecaseProvider,
        );

        await createDvcPointContractUsecase.execute(
          groupId: group.id,
          contractName: contractName,
          useYearStartMonth: useYearStartMonth,
          annualPoint: annualPoint,
        );

        contractNameController.clear();
        annualPointController.clear();

        await loadData();
        await showMessage('契約を登録しました。');
      } catch (_) {
        await showMessage('契約登録に失敗しました。');
      }
    }

    Future<void> handleCreateUsage() async {
      try {
        final usageYearMonth = _parseYearMonth(
          usageMonthController.text.trim(),
        );
        final usedPoint = int.tryParse(usagePointController.text.trim());
        final memo = usageMemoController.text.trim();

        if (usageYearMonth == null || usedPoint == null || usedPoint <= 0) {
          await showMessage('利用年月と利用ポイントを正しく入力してください。');
          return;
        }

        final available = _findAvailablePointForMonth(
          monthlySummaries.value,
          usageYearMonth,
        );
        if (available != null && usedPoint > available) {
          await showMessage('利用可能ポイントを超えています。');
          return;
        }

        final createDvcPointUsageUsecase = ref.read(
          createDvcPointUsageUsecaseProvider,
        );

        await createDvcPointUsageUsecase.execute(
          groupId: group.id,
          usageYearMonth: usageYearMonth,
          usedPoint: usedPoint,
          memo: memo.isEmpty ? null : memo,
        );

        usagePointController.clear();
        usageMemoController.clear();

        await loadData();
        await showMessage('利用登録を保存しました。');
      } catch (_) {
        await showMessage('利用登録に失敗しました。');
      }
    }

    Future<void> handleCreateLimitedPoint() async {
      try {
        final startYearMonth = _parseYearMonth(
          limitedStartMonthController.text.trim(),
        );
        final endYearMonth = _parseYearMonth(
          limitedEndMonthController.text.trim(),
        );
        final point = int.tryParse(limitedPointController.text.trim());
        final memo = limitedMemoController.text.trim();

        if (startYearMonth == null ||
            endYearMonth == null ||
            point == null ||
            point <= 0) {
          await showMessage('開始年月・終了年月・ポイント数を正しく入力してください。');
          return;
        }

        if (_compareMonth(startYearMonth, endYearMonth) > 0) {
          await showMessage('終了年月は開始年月以降を指定してください。');
          return;
        }

        final createDvcLimitedPointUsecase = ref.read(
          createDvcLimitedPointUsecaseProvider,
        );

        await createDvcLimitedPointUsecase.execute(
          groupId: group.id,
          startYearMonth: startYearMonth,
          endYearMonth: endYearMonth,
          point: point,
          memo: memo.isEmpty ? null : memo,
        );

        limitedPointController.clear();
        limitedMemoController.clear();

        await loadData();
        await showMessage('期間限定ポイントを登録しました。');
      } catch (_) {
        await showMessage('期間限定ポイント登録に失敗しました。');
      }
    }

    Widget buildBody() {
      if (isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (errorMessage.value != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage.value!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: loadData, child: const Text('再読み込み')),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContractSection(
              contracts: contracts.value,
              contractNameController: contractNameController,
              useYearStartMonthController: useYearStartMonthController,
              annualPointController: annualPointController,
              onCreateContract: handleCreateContract,
            ),
            const SizedBox(height: 16),
            _buildPointTableSection(
              context,
              summaries: monthlySummaries.value,
              onTapAvailableCell: (summary) => _showAvailableBreakdownDialog(
                context,
                summary.availableBreakdowns,
              ),
              onTapUsedCell: (summary) =>
                  _showUsageDetailsDialog(context, summary.usageDetails),
            ),
            const SizedBox(height: 16),
            _buildUsageFormSection(
              usageMonthController: usageMonthController,
              usagePointController: usagePointController,
              usageMemoController: usageMemoController,
              onCreateUsage: handleCreateUsage,
            ),
            const SizedBox(height: 16),
            _buildLimitedPointFormSection(
              limitedStartMonthController: limitedStartMonthController,
              limitedEndMonthController: limitedEndMonthController,
              limitedPointController: limitedPointController,
              limitedMemoController: limitedMemoController,
              onCreateLimitedPoint: handleCreateLimitedPoint,
            ),
          ],
        ),
      );
    }

    return Container(
      key: const Key('dvc_point_calculation_screen'),
      child: Column(
        children: [
          AppBar(
            leading: IconButton(
              key: const Key('dvc_back_button'),
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed,
            ),
            title: Text(group.name),
          ),
          Expanded(child: buildBody()),
        ],
      ),
    );
  }

  Widget _buildContractSection({
    required List<DvcPointContractDto> contracts,
    required TextEditingController contractNameController,
    required TextEditingController useYearStartMonthController,
    required TextEditingController annualPointController,
    required Future<void> Function() onCreateContract,
  }) {
    return Card(
      key: const Key('dvc_point_table'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '契約管理',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (contracts.isEmpty)
              const Text('契約が登録されていません。下のフォームから登録してください。')
            else
              Column(
                children: contracts
                    .map(
                      (contract) => ListTile(
                        key: Key('dvc_contract_item_${contract.id}'),
                        title: Text(contract.contractName),
                        subtitle: Text(
                          'ユースイヤー開始月: ${contract.useYearStartMonth}月 / 年間${contract.annualPoint}pt',
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            const Divider(),
            TextField(
              key: const Key('dvc_contract_name_input'),
              controller: contractNameController,
              decoration: const InputDecoration(labelText: '契約名'),
            ),
            TextField(
              key: const Key('dvc_contract_use_year_start_month_input'),
              controller: useYearStartMonthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ユースイヤー開始月 (1-12)'),
            ),
            TextField(
              key: const Key('dvc_contract_annual_point_input'),
              controller: annualPointController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '付与ポイント数'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                key: const Key('dvc_contract_add_button'),
                onPressed: onCreateContract,
                child: const Text('契約を登録'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointTableSection(
    BuildContext context, {
    required List<DvcPointMonthlySummaryDto> summaries,
    required void Function(DvcPointMonthlySummaryDto summary)
    onTapAvailableCell,
    required void Function(DvcPointMonthlySummaryDto summary) onTapUsedCell,
  }) {
    if (summaries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('表示できるDVCポイントデータがありません。'),
        ),
      );
    }

    const rowLabelWidth = 120.0;
    const monthCellWidth = 88.0;

    final yearGroups = _buildYearGroups(summaries);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DVCポイント計算テーブル',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildTableLabelCell('年', width: rowLabelWidth),
                      ...yearGroups.map(
                        (group) => _buildTableCell(
                          key: Key('dvc_year_cell_${group.year}'),
                          text: '${group.year}年',
                          width: monthCellWidth * group.monthCount,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabelCell('月', width: rowLabelWidth),
                      ...summaries.map(
                        (summary) => _buildTableCell(
                          key: Key(
                            'dvc_month_cell_${_formatYearMonth(summary.yearMonth)}',
                          ),
                          text: '${summary.yearMonth.month}月',
                          width: monthCellWidth,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabelCell('利用可能ポイント', width: rowLabelWidth),
                      ...summaries.map(
                        (summary) => InkWell(
                          key: Key(
                            'dvc_available_cell_${_formatYearMonth(summary.yearMonth)}',
                          ),
                          onTap: () => onTapAvailableCell(summary),
                          child: _buildTableCell(
                            text: '${summary.availablePoint}',
                            width: monthCellWidth,
                            backgroundColor: Colors.green.shade50,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabelCell('利用登録済みポイント', width: rowLabelWidth),
                      ...summaries.map(
                        (summary) => InkWell(
                          key: Key(
                            'dvc_used_cell_${_formatYearMonth(summary.yearMonth)}',
                          ),
                          onTap: () => onTapUsedCell(summary),
                          child: _buildTableCell(
                            text: '${summary.usedPoint}',
                            width: monthCellWidth,
                            backgroundColor: Colors.orange.shade50,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageFormSection({
    required TextEditingController usageMonthController,
    required TextEditingController usagePointController,
    required TextEditingController usageMemoController,
    required Future<void> Function() onCreateUsage,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '利用登録',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              key: const Key('dvc_usage_month_input'),
              controller: usageMonthController,
              decoration: const InputDecoration(labelText: '利用年月 (YYYY-MM)'),
            ),
            TextField(
              key: const Key('dvc_usage_point_input'),
              controller: usagePointController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '利用ポイント数'),
            ),
            TextField(
              key: const Key('dvc_usage_memo_input'),
              controller: usageMemoController,
              decoration: const InputDecoration(labelText: 'メモ (任意)'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                key: const Key('dvc_usage_add_button'),
                onPressed: onCreateUsage,
                child: const Text('利用を登録'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitedPointFormSection({
    required TextEditingController limitedStartMonthController,
    required TextEditingController limitedEndMonthController,
    required TextEditingController limitedPointController,
    required TextEditingController limitedMemoController,
    required Future<void> Function() onCreateLimitedPoint,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '期間限定ポイント登録',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              key: const Key('dvc_limited_start_month_input'),
              controller: limitedStartMonthController,
              decoration: const InputDecoration(labelText: '開始年月 (YYYY-MM)'),
            ),
            TextField(
              key: const Key('dvc_limited_end_month_input'),
              controller: limitedEndMonthController,
              decoration: const InputDecoration(labelText: '終了年月 (YYYY-MM)'),
            ),
            TextField(
              key: const Key('dvc_limited_point_input'),
              controller: limitedPointController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ポイント数'),
            ),
            TextField(
              key: const Key('dvc_limited_memo_input'),
              controller: limitedMemoController,
              decoration: const InputDecoration(labelText: 'メモ (任意)'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                key: const Key('dvc_limited_add_button'),
                onPressed: onCreateLimitedPoint,
                child: const Text('期間限定ポイントを登録'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableLabelCell(String text, {required double width}) {
    return _buildTableCell(
      text: text,
      width: width,
      backgroundColor: Colors.grey.shade300,
      fontWeight: FontWeight.bold,
    );
  }

  Widget _buildTableCell({
    required String text,
    required double width,
    Key? key,
    Color? backgroundColor,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Container(
      key: key,
      width: width,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: fontWeight),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _showAvailableBreakdownDialog(
    BuildContext context,
    List<DvcPointAvailableBreakdownDto> values,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('利用可能ポイント内訳'),
          content: values.isEmpty
              ? const Text('内訳データがありません。')
              : SizedBox(
                  width: 360,
                  child: ListView(
                    shrinkWrap: true,
                    children: values
                        .map(
                          (value) => ListTile(
                            title: Text(value.label),
                            subtitle: Text('${value.point}pt'),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUsageDetailsDialog(
    BuildContext context,
    List<DvcPointUsageDetailDto> values,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('利用登録済みポイント内訳'),
          content: values.isEmpty
              ? const Text('利用登録はありません。')
              : SizedBox(
                  width: 360,
                  child: ListView(
                    shrinkWrap: true,
                    children: values
                        .map(
                          (value) => ListTile(
                            title: Text('${value.point}pt'),
                            subtitle: Text(value.memo ?? ''),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  int? _findAvailablePointForMonth(
    List<DvcPointMonthlySummaryDto> summaries,
    DateTime month,
  ) {
    for (final summary in summaries) {
      if (_isSameYearMonth(summary.yearMonth, month)) {
        return summary.availablePoint;
      }
    }
    return null;
  }

  List<DateTime> _buildTargetMonths({
    required List<DvcPointContractDto> contracts,
    required List<DvcPointUsageDto> usages,
    required List<DvcLimitedPointDto> limitedPoints,
  }) {
    if (contracts.isEmpty && usages.isEmpty && limitedPoints.isEmpty) {
      final now = DateTime.now();
      return [DateTime(now.year, now.month)];
    }

    DateTime? minMonth;
    DateTime? maxMonth;

    for (final contract in contracts) {
      final start = _addMonths(
        _startOfMonth(contract.contractStartYearMonth),
        -12,
      );
      final end = _addMonths(_startOfMonth(contract.contractEndYearMonth), 12);
      minMonth = minMonth == null || _compareMonth(start, minMonth) < 0
          ? start
          : minMonth;
      maxMonth = maxMonth == null || _compareMonth(end, maxMonth) > 0
          ? end
          : maxMonth;
    }

    for (final usage in usages) {
      final month = _startOfMonth(usage.usageYearMonth);
      minMonth = minMonth == null || _compareMonth(month, minMonth) < 0
          ? month
          : minMonth;
      maxMonth = maxMonth == null || _compareMonth(month, maxMonth) > 0
          ? month
          : maxMonth;
    }

    for (final limitedPoint in limitedPoints) {
      final start = _startOfMonth(limitedPoint.startYearMonth);
      final end = _startOfMonth(limitedPoint.endYearMonth);
      minMonth = minMonth == null || _compareMonth(start, minMonth) < 0
          ? start
          : minMonth;
      maxMonth = maxMonth == null || _compareMonth(end, maxMonth) > 0
          ? end
          : maxMonth;
    }

    final result = <DateTime>[];
    if (minMonth == null || maxMonth == null) {
      final now = DateTime.now();
      return [DateTime(now.year, now.month)];
    }

    var current = minMonth;
    var count = 0;
    while (_compareMonth(current, maxMonth) <= 0 && count < 48) {
      result.add(current);
      current = _addMonths(current, 1);
      count++;
    }

    return result;
  }

  List<_YearGroup> _buildYearGroups(List<DvcPointMonthlySummaryDto> summaries) {
    final groups = <_YearGroup>[];

    for (final summary in summaries) {
      final year = summary.yearMonth.year;
      if (groups.isEmpty || groups.last.year != year) {
        groups.add(_YearGroup(year: year, monthCount: 1));
      } else {
        final last = groups.removeLast();
        groups.add(last.copyWith(monthCount: last.monthCount + 1));
      }
    }

    return groups;
  }

  DateTime _startOfMonth(DateTime value) {
    return DateTime(value.year, value.month);
  }

  int _compareMonth(DateTime a, DateTime b) {
    if (a.year != b.year) {
      return a.year.compareTo(b.year);
    }
    return a.month.compareTo(b.month);
  }

  bool _isSameYearMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }
}

DateTime _addMonths(DateTime value, int months) {
  final totalMonths = value.year * 12 + value.month - 1 + months;
  final year = totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  return DateTime(year, month);
}

DateTime? _parseYearMonth(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value);
  if (match == null) {
    return null;
  }

  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  if (year == null || month == null || month < 1 || month > 12) {
    return null;
  }

  return DateTime(year, month);
}

String _formatYearMonth(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  return '${value.year}-$month';
}

class _YearGroup {
  _YearGroup({required this.year, required this.monthCount});

  final int year;
  final int monthCount;

  _YearGroup copyWith({int? year, int? monthCount}) {
    return _YearGroup(
      year: year ?? this.year,
      monthCount: monthCount ?? this.monthCount,
    );
  }
}
