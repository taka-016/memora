import 'package:flutter/material.dart';
import 'package:memora/application/usecases/dvc/calculate_dvc_point_table_usecase.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';

Future<void> showDvcAvailableBreakdownModal({
  required BuildContext context,
  required DateTime month,
  required List<DvcAvailablePointBreakdown> breakdowns,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('${dvcFormatYearMonth(month)}\n利用可能ポイント内訳'),
        content: SizedBox(
          width: 520,
          child: breakdowns.isEmpty
              ? const Text('内訳がありません')
              : ListView(
                  shrinkWrap: true,
                  children: breakdowns.map((breakdown) {
                    final memo = breakdown.memo?.trim() ?? '';
                    return ListTile(
                      title: Text(
                        '${breakdown.sourceName}: ${breakdown.remainingPoint}pt',
                      ),
                      subtitle: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (breakdown.useYear != null)
                            Text('${breakdown.useYear}ユースイヤー'),
                          Text(
                            '有効期限: ${dvcFormatYearMonth(breakdown.expireAt)}',
                          ),
                          if (memo.isNotEmpty) Text(memo),
                        ],
                      ),
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
