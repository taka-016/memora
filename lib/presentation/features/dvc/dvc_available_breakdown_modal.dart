import 'package:flutter/material.dart';
import 'package:memora/application/usecases/dvc/calculate_dvc_point_table_usecase.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';
import 'package:memora/presentation/shared/dialogs/delete_confirm_dialog.dart';

typedef DvcLimitedPointDeleteCallback =
    Future<void> Function(String limitedPointId);

Future<void> showDvcAvailableBreakdownModal({
  required BuildContext context,
  required DateTime month,
  required List<DvcAvailablePointBreakdown> breakdowns,
  DvcLimitedPointDeleteCallback? onDeleteLimitedPoint,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
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
                    final expireLabel =
                        '${dvcFormatYearMonth(breakdown.availableFrom)}〜'
                        '${dvcFormatYearMonth(breakdown.expireAt)}';
                    final subtitleChildren = <Widget>[
                      if (breakdown.useYear != null)
                        Text('${breakdown.useYear}ユースイヤー'),
                    ];
                    if (breakdown.sourceType == DvcPointSourceType.limited) {
                      if (memo.isNotEmpty) {
                        subtitleChildren.add(Text(memo));
                      }
                      subtitleChildren.add(Text(expireLabel));
                    } else {
                      subtitleChildren.add(Text(expireLabel));
                      if (memo.isNotEmpty) {
                        subtitleChildren.add(Text(memo));
                      }
                    }
                    return ListTile(
                      title: Text(
                        '${breakdown.sourceName}: ${breakdown.remainingPoint}pt',
                      ),
                      subtitle: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: subtitleChildren,
                      ),
                      trailing:
                          breakdown.sourceType == DvcPointSourceType.limited &&
                              onDeleteLimitedPoint != null
                          ? IconButton(
                              key: ValueKey(
                                'dvc_limited_point_delete_button_${breakdown.sourceId}',
                              ),
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final confirmed =
                                    await DeleteConfirmDialog.show(
                                      dialogContext,
                                      title: '削除確認',
                                      content: '期間限定ポイントを削除しますか？',
                                      onConfirm: () {},
                                    );
                                if (confirmed != true) {
                                  return;
                                }
                                if (!dialogContext.mounted) {
                                  return;
                                }
                                Navigator.of(dialogContext).pop();
                                await onDeleteLimitedPoint(breakdown.sourceId);
                              },
                            )
                          : null,
                    );
                  }).toList(),
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
