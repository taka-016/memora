import 'package:flutter/material.dart';

class EditDiscardConfirmDialog extends StatelessWidget {
  const EditDiscardConfirmDialog({
    super.key,
    this.title = '変更内容の確認',
    this.content = '変更内容が保存されていません。破棄しますか？',
    this.continueLabel = '編集を続ける',
    this.discardLabel = '破棄する',
  });

  final String title;
  final String content;
  final String continueLabel;
  final String discardLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(continueLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(discardLabel),
        ),
      ],
    );
  }

  static Future<bool> show(
    BuildContext context, {
    String title = '変更内容の確認',
    String content = '変更内容が保存されていません。破棄しますか？',
    String continueLabel = '編集を続ける',
    String discardLabel = '破棄する',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditDiscardConfirmDialog(
        title: title,
        content: content,
        continueLabel: continueLabel,
        discardLabel: discardLabel,
      ),
    );
    return result ?? false;
  }
}
