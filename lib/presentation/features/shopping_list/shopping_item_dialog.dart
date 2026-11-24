import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/shopping_list/shopping_list_item.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/shopping_list_providers.dart';

Future<bool?> showShoppingItemEditDialog(
  BuildContext context,
  String groupId, {
  required ShoppingListItem item,
  bool editQuantityOnly = false,
}) => showDialog<bool>(
  context: context,
  builder: (_) => _ShoppingItemDialog(
    groupId: groupId,
    item: item,
    editQuantityOnly: editQuantityOnly,
  ),
);

class _ShoppingItemDialog extends HookConsumerWidget {
  const _ShoppingItemDialog({
    required this.groupId,
    required this.item,
    required this.editQuantityOnly,
  });

  final String groupId;
  final ShoppingListItem item;
  final bool editQuantityOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(shoppingListProvider);
    final name = useTextEditingController(text: item.name);
    final quantity = useTextEditingController(text: item.pendingQuantity);
    final saving = useState(false);
    final message = useState<String?>(null);

    Future<void> save() async {
      if (saving.value) return;
      saving.value = true;
      message.value = null;
      try {
        final duplicate = await list.edit(
          groupId,
          item,
          name.text,
          quantity.text,
        );
        if (!context.mounted) return;
        if (duplicate == null) {
          Navigator.of(context).pop(true);
        } else {
          message.value = '同じ品物名が一覧にあります。';
        }
      } catch (error) {
        if (context.mounted) {
          message.value = error is ApplicationValidationException
              ? error.message
              : '品物を保存できませんでした。再試行してください。';
        }
      } finally {
        if (context.mounted) saving.value = false;
      }
    }

    return PopScope(
      canPop: !saving.value,
      child: AlertDialog(
        title: const Text('品物を編集'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (editQuantityOnly) const Text('この品物は一覧にあります。既存の数量を編集できます。'),
            TextField(
              controller: name,
              enabled: !saving.value,
              readOnly: editQuantityOnly,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: '品物名'),
            ),
            TextField(
              controller: quantity,
              autofocus: editQuantityOnly,
              enabled: !saving.value,
              onSubmitted: (_) => save(),
              decoration: const InputDecoration(
                labelText: '数量（任意）',
                hintText: '2個、500g',
              ),
            ),
            if (message.value case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(message),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: saving.value ? null : () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: saving.value ? null : save,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
