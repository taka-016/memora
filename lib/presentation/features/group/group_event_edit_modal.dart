import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/core/app_logger.dart';

Future<void> showGroupEventEditModal({
  required BuildContext context,
  required int selectedYear,
  required String initialMemo,
  required Future<void> Function(String memo) onSave,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) {
      return _GroupEventEditDialog(
        selectedYear: selectedYear,
        initialMemo: initialMemo,
        onSave: onSave,
      );
    },
  );
}

class _GroupEventEditDialog extends HookWidget {
  const _GroupEventEditDialog({
    required this.selectedYear,
    required this.initialMemo,
    required this.onSave,
  });

  final int selectedYear;
  final String initialMemo;
  final Future<void> Function(String memo) onSave;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initialMemo);
    final isSaving = useState(false);
    final isSavingRef = useRef(false);

    return AlertDialog(
      key: Key('group_event_edit_dialog_$selectedYear'),
      title: Text('イベント編集（$selectedYear年）'),
      content: TextField(
        key: Key('group_event_edit_field_$selectedYear'),
        controller: controller,
        autofocus: true,
        minLines: 4,
        maxLines: 8,
        decoration: const InputDecoration(
          hintText: 'この年の出来事や予定を入力',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving.value ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          key: Key('group_event_save_button_$selectedYear'),
          onPressed: () async {
            if (isSavingRef.value) {
              return;
            }
            isSavingRef.value = true;
            isSaving.value = true;
            final memo = controller.text.trim();
            try {
              await onSave(memo);

              if (!context.mounted) return;
              Navigator.of(context).pop();
            } catch (e, stack) {
              logger.e(
                'showGroupEventEditModal: ${e.toString()}',
                error: e,
                stackTrace: stack,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('グループイベントの保存に失敗しました')),
              );
            } finally {
              isSavingRef.value = false;
              if (context.mounted) {
                isSaving.value = false;
              }
            }
          },
          child: isSaving.value
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}
