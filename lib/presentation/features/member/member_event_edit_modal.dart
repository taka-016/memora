import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/core/app_logger.dart';

Future<void> showMemberEventEditModal({
  required BuildContext context,
  required String memberId,
  required String memberName,
  required int selectedYear,
  required String initialMemo,
  required Future<void> Function(String memo) onSave,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) {
      return _MemberEventEditDialog(
        memberId: memberId,
        memberName: memberName,
        selectedYear: selectedYear,
        initialMemo: initialMemo,
        onSave: onSave,
      );
    },
  );
}

class _MemberEventEditDialog extends HookWidget {
  const _MemberEventEditDialog({
    required this.memberId,
    required this.memberName,
    required this.selectedYear,
    required this.initialMemo,
    required this.onSave,
  });

  final String memberId;
  final String memberName;
  final int selectedYear;
  final String initialMemo;
  final Future<void> Function(String memo) onSave;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initialMemo);

    return AlertDialog(
      key: Key('member_event_edit_dialog_${memberId}_$selectedYear'),
      title: Text('$memberName（$selectedYear年）'),
      content: TextField(
        key: Key('member_event_edit_field_${memberId}_$selectedYear'),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          key: Key('member_event_save_button_${memberId}_$selectedYear'),
          onPressed: () async {
            final memo = controller.text.trim();
            try {
              await onSave(memo);

              if (!context.mounted) return;
              Navigator.of(context).pop();
            } catch (e, stack) {
              logger.e(
                'showMemberEventEditModal: ${e.toString()}',
                error: e,
                stackTrace: stack,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('メンバーイベントの保存に失敗しました')),
              );
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
