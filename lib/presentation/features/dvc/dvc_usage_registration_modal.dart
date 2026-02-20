import 'package:flutter/material.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';

typedef DvcUsageSaveCallback =
    Future<void> Function({
      required DateTime usageYearMonth,
      required int usedPoint,
      required String memo,
    });

Future<void> showDvcUsageRegistrationModal({
  required BuildContext context,
  required DateTime targetYearMonth,
  required int maxAvailablePoint,
  required DvcUsageSaveCallback onSave,
}) async {
  final pointController = TextEditingController();
  final memoController = TextEditingController();
  var validationError = '';

  await showDialog<void>(
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
                  Text('${dvcFormatYearMonth(targetYearMonth)}の利用登録'),
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
                  await onSave(
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
