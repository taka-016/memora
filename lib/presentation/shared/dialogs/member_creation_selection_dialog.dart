import 'package:flutter/material.dart';

enum MemberCreationOption { createNew, useInvitationCode, backToLogin }

class MemberCreationSelectionDialog extends StatelessWidget {
  const MemberCreationSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('メンバー作成'),
      content: const Text('新規作成または招待コードの入力を選択してください。'),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(MemberCreationOption.createNew),
          child: const Text('新規作成'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(MemberCreationOption.useInvitationCode),
          child: const Text('招待コード入力'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(MemberCreationOption.backToLogin),
          child: const Text('ログイン画面に戻る'),
        ),
      ],
    );
  }

  static Future<MemberCreationOption?> show(BuildContext context) {
    return showDialog<MemberCreationOption>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const MemberCreationSelectionDialog(),
    );
  }
}
