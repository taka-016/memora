import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/shopping_list_providers.dart';
import 'package:memora/presentation/features/shopping_list/shopping_item_dialog.dart';

class ShoppingItemAddForm extends HookConsumerWidget {
  const ShoppingItemAddForm({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = useTextEditingController();
    final quantity = useTextEditingController();
    final quantityFocus = useFocusNode();
    final saving = useState(false);
    final message = useState<String?>(null);

    Future<void> add() async {
      if (saving.value) return;
      final list = ref.read(shoppingListProvider);
      saving.value = true;
      message.value = null;
      try {
        final existing = await list.add(groupId, name.text, quantity.text);
        if (!context.mounted) return;
        if (existing != null) {
          final edited = await showShoppingItemEditDialog(
            context,
            groupId,
            item: existing,
            editQuantityOnly: true,
          );
          if (!context.mounted || edited != true) return;
        }
        name.clear();
        quantity.clear();
      } catch (error) {
        if (context.mounted) {
          message.value = error is ApplicationValidationException
              ? error.message
              : '品物を追加できませんでした。再試行してください。';
        }
      } finally {
        if (context.mounted) saving.value = false;
      }
    }

    Future<void> chooseFromHistory() async {
      final list = ref.read(shoppingListProvider);
      final chosenName = await showShoppingAdditionsDialog(
        context,
        () => list.additions(groupId),
      );
      if (!context.mounted || chosenName == null) return;
      name.text = chosenName;
      quantity.clear();
      message.value = null;
      quantityFocus.requestFocus();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: name,
                  enabled: !saving.value,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => quantityFocus.requestFocus(),
                  decoration: const InputDecoration(
                    labelText: '品物名',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: quantity,
                  focusNode: quantityFocus,
                  enabled: !saving.value,
                  onSubmitted: (_) => add(),
                  decoration: const InputDecoration(
                    labelText: '数量',
                    hintText: '2個、500g',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: saving.value ? null : add,
                child: const Text('追加'),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: saving.value ? null : chooseFromHistory,
            icon: const Icon(Icons.history),
            label: const Text('追加履歴から選ぶ'),
          ),
          if (message.value case final error?)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
