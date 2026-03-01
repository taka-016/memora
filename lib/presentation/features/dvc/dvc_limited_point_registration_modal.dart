import 'package:flutter/material.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';
import 'package:memora/presentation/features/dvc/dvc_year_month_selector.dart';

typedef DvcLimitedPointSaveCallback =
    Future<void> Function({
      required DateTime startYearMonth,
      required DateTime endYearMonth,
      required int point,
      required String memo,
    });

Future<void> showDvcLimitedPointRegistrationModal({
  required BuildContext context,
  required DvcLimitedPointSaveCallback onSave,
}) async {
  var startYearMonth = dvcMonthStart(DateTime.now());
  var endYearMonth = dvcMonthStart(DateTime.now());
  final pointController = TextEditingController();
  final memoController = TextEditingController();
  var validationError = '';

  await showDialog<void>(
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
                  await onSave(
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
