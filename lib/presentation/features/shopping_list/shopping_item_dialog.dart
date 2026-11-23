import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/shopping_list/shopping_list_item.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/usecases/shopping_list/shopping_list.dart';
import 'package:memora/composition_root/providers/shopping_list_providers.dart';

Future<void> showShoppingItemDialog(
  BuildContext context,
  String groupId, {
  ShoppingListItem? item,
}) => showDialog<void>(
  context: context,
  builder: (_) => _ShoppingItemDialog(groupId: groupId, initialItem: item),
);

class _ShoppingItemDialog extends HookConsumerWidget {
  const _ShoppingItemDialog({required this.groupId, this.initialItem});

  final String groupId;
  final ShoppingListItem? initialItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(shoppingListProvider);
    final item = useState(initialItem);
    final name = useTextEditingController(text: initialItem?.name);
    final quantity = useTextEditingController(
      text: initialItem?.pendingQuantity,
    );
    final quantityFocus = useFocusNode();
    final saving = useState(false);
    final message = useState<String?>(null);

    Future<void> save() async {
      if (saving.value) return;
      saving.value = true;
      message.value = null;
      try {
        final current = item.value;
        final duplicate = current == null
            ? await list.add(groupId, name.text, quantity.text)
            : await list.edit(groupId, current, name.text, quantity.text);
        if (!context.mounted) return;
        if (duplicate == null) {
          Navigator.of(context).pop();
          return;
        }
        if (current == null) {
          item.value = duplicate;
          name.text = duplicate.name;
          quantity.text = duplicate.pendingQuantity!;
          quantityFocus.requestFocus();
          message.value = 'この品物は一覧にあります。既存の数量を編集できます。';
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
        title: Text(item.value == null ? '品物を追加' : '品物を編集'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.value == null)
              TextButton.icon(
                onPressed: saving.value
                    ? null
                    : () async {
                        final chosenName = await showDialog<String>(
                          context: context,
                          builder: (_) => _ShoppingAdditionsDialog(
                            load: () => list.additions(groupId),
                          ),
                        );
                        if (!context.mounted || chosenName == null) return;
                        name.text = chosenName;
                        quantity.clear();
                        quantityFocus.requestFocus();
                      },
                icon: const Icon(Icons.history),
                label: const Text('追加履歴から選ぶ'),
              ),
            TextField(
              controller: name,
              enabled: !saving.value,
              readOnly: initialItem == null && item.value != null,
              maxLength: ShoppingList.NAME_MAX_LENGTH,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '品物名',
                counterText: '',
              ),
            ),
            TextField(
              controller: quantity,
              focusNode: quantityFocus,
              enabled: !saving.value,
              maxLength: ShoppingList.QUANTITY_MAX_LENGTH,
              onSubmitted: (_) => save(),
              decoration: const InputDecoration(
                labelText: '数量（任意）',
                hintText: '2個、500g',
                counterText: '',
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

class _ShoppingAdditionsDialog extends HookWidget {
  const _ShoppingAdditionsDialog({required this.load});

  final Future<List<ShoppingListItem>> Function() load;

  @override
  Widget build(BuildContext context) {
    final retry = useState(0);
    final history = useFuture(useMemoized(load, [retry.value]));
    return SimpleDialog(
      title: const Text('追加履歴'),
      children: [
        if (history.connectionState != ConnectionState.done)
          const Center(child: CircularProgressIndicator())
        else if (history.hasError)
          SimpleDialogOption(
            onPressed: () => retry.value++,
            child: const Text('読み込めませんでした。再読み込み'),
          )
        else if (history.data!.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('追加履歴がありません'))
        else
          for (final item in history.data!)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(item.name),
              child: Text(item.name),
            ),
      ],
    );
  }
}
