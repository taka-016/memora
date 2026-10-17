import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:flutter/material.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';

typedef DvcUsageSaveCallback = Future<bool> Function({
  required String contractId,
  required DateTime usageYearMonth,
  required int usedPoint,
  required String memo,
});

Future<void> showDvcUsageRegistrationModal({
  required BuildContext context,
  required List<DvcPointContractDto> contracts,
  required DateTime targetYearMonth,
  required Map<String, int> availablePointsByContract,
  required DvcUsageSaveCallback onSave,
}) async {
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
              title: const Text('ポイント利用登録'),
              content: AbsorbPointer(
                absorbing: isSaving,
                child: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (contracts.isEmpty) const Text('先に契約を登録してください'),
                        DropdownButtonFormField<String>(
                          key: const Key('dvc_usage_contract_field'),
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
                        Text(
                          '利用可能ポイント: ${availablePointsByContract[contractId] ?? 0}pt',
                        ),
                        Text('${dvcFormatYearMonth(targetYearMonth)}の利用登録'),
                        TextField(
                          key: const Key('dvc_usage_point_field'),
                          controller: pointController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '利用ポイント',
                          ),
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
                          final usedPoint =
                              int.tryParse(pointController.text) ?? 0;
                          if (usedPoint <= 0) {
                            setState(() {
                              validationError = '利用ポイントを入力してください';
                            });
                            return;
                          }
                          if (usedPoint >
                              (availablePointsByContract[contractId] ?? 0)) {
                            setState(() {
                              validationError = '利用可能ポイントを超えています';
                            });
                            return;
                          }
                          setState(() {
                            isSaving = true;
                          });
                          try {
                            final didSave = await onSave(
                              contractId: contractId!,
                              usageYearMonth: targetYearMonth,
                              usedPoint: usedPoint,
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
