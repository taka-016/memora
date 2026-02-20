import 'package:flutter/material.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';

typedef DvcUsageDeleteCallback = Future<void> Function(String pointUsageId);

Future<void> showDvcUsageBreakdownModal({
  required BuildContext context,
  required DateTime month,
  required List<DvcPointUsageDto> usages,
  required DvcUsageDeleteCallback onDelete,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('${dvcFormatYearMonth(month)}\n利用ポイント内訳'),
        content: SizedBox(
          width: 520,
          child: usages.isEmpty
              ? const Text('利用登録がありません')
              : ListView(
                  shrinkWrap: true,
                  children: usages.map((usage) {
                    final memo = usage.memo?.isEmpty ?? true ? '' : usage.memo!;
                    return ListTile(
                      title: Text('${usage.usedPoint}pt'),
                      subtitle: memo.isEmpty ? null : Text(memo),
                      trailing: IconButton(
                        key: ValueKey('dvc_usage_delete_button_${usage.id}'),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await onDelete(usage.id);
                        },
                      ),
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
