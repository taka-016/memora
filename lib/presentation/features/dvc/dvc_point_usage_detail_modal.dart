import 'package:flutter/material.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';

Future<void> showDvcPointUsageDetailModal({
  required BuildContext context,
  required int selectedYear,
  required List<DvcPointUsageDto> usages,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        key: Key('dvc_point_usage_detail_dialog_$selectedYear'),
        title: Text('DVCポイント利用詳細（$selectedYear年）'),
        content: SizedBox(
          width: 480,
          height: 360,
          child: usages.isEmpty
              ? const Center(child: Text('利用履歴がありません'))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: usages.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (_, index) {
                    final usage = usages[index];
                    final memo = usage.memo?.trim() ?? '';
                    final displayMemo = memo.isEmpty ? 'なし' : memo;

                    return Column(
                      key: Key('dvc_point_usage_detail_item_${usage.id}'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '利用年月: ${dvcFormatYearMonth(usage.usageYearMonth)}',
                        ),
                        Text('利用ポイント: ${usage.usedPoint}pt'),
                        Text('メモ: $displayMemo'),
                      ],
                    );
                  },
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
