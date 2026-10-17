import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:flutter/material.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';
import 'package:memora/presentation/features/dvc/dvc_year_month_selector.dart';

typedef DvcLimitedPointSaveCallback = Future<bool> Function({
  required String contractId,
  required DateTime startYearMonth,
  required DateTime endYearMonth,
  required int point,
  required String memo,
});

Future<void> showDvcLimitedPointRegistrationModal({
  required BuildContext context,
  required List<DvcPointContractDto> contracts,
  required DvcLimitedPointSaveCallback onSave,
  required AppClock clock,
}) async {
  final now = clock.now();
  var startYearMonth = dvcMonthStart(now);
  var endYearMonth = dvcMonthStart(now);
  final pointController = TextEditingController();
  final memoController = TextEditingController();
  var validationError = '';
  var isSaving = false;
  String? contractId = contracts.isEmpty ? null : contracts.first.id;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return PopScope(
            canPop: !isSaving,
            child: AlertDialog(
              title: const Text('期間限定ポイント登録'),
              content: AbsorbPointer(
                absorbing: isSaving,
                child: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (contracts.isEmpty) const Text('先に契約を登録してください'),
                        DropdownButtonFormField<String>(
                          key: const Key('dvc_limited_contract_field'),
                          initialValue: contractId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: '契約'),
                          items: contracts
                              .map(
                                (contract) => DropdownMenuItem(
                                  value: contract.id,
                                  child: Text(contract.contractName),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() {
                            contractId = value;
                            validationError = '';
                          }),
                        ),
                        DvcYearMonthSelector(
                          label: '開始年月',
                          selected: startYearMonth,
                          onSelected: (value) {
                            setState(() {
                              startYearMonth = value;
                            });
                          },
                        ),
                        DvcYearMonthSelector(
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
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: isSaving || contractId == null
                      ? null
                      : () async {
                          if (isSaving) return;
                          final point = int.tryParse(pointController.text) ?? 0;
                          if (point <= 0 ||
                              endYearMonth.isBefore(startYearMonth)) {
                            setState(() {
                              validationError = '入力内容を確認してください';
                            });
                            return;
                          }
                          setState(() {
                            isSaving = true;
                          });
                          try {
                            final didSave = await onSave(
                              contractId: contractId!,
                              startYearMonth: startYearMonth,
                              endYearMonth: endYearMonth,
                              point: point,
                              memo: memoController.text.trim(),
                            );
                            if (didSave && dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } finally {
                            if (dialogContext.mounted)
                              setState(() {
                                isSaving = false;
                              });
                          }
                        },
                  child: const Text('登録'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
