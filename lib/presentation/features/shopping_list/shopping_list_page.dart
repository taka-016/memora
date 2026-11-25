import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/shopping_list_item_dto.dart';
import 'package:memora/presentation/notifiers/shopping_list/shopping_list_notifier.dart';

class ShoppingListPage extends HookConsumerWidget {
  const ShoppingListPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.onBack,
  });

  final String groupId;
  final String groupName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = shoppingListNotifierProvider(groupId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final name = useTextEditingController();
    final quantity = useTextEditingController();
    useListenable(name);
    final canAdd =
        state.unchecked.hasValue &&
        !state.saving &&
        name.text.trim().isNotEmpty;

    Future<void> add() async {
      if (!canAdd) return;
      final enteredName = name.text.trim();
      final enteredQuantity = quantity.text.trim();
      final existing = state.unchecked.requireValue
          .where((item) => item.name == enteredName)
          .firstOrNull;
      final saved = existing == null
          ? await _save(
              context,
              () => notifier.add(enteredName, enteredQuantity),
              retry: false,
            )
          : await _editExistingQuantity(
              context,
              notifier,
              existing,
              enteredQuantity,
            );
      if (saved && context.mounted) {
        if (name.text.trim() == enteredName) name.clear();
        if (quantity.text.trim() == enteredQuantity) quantity.clear();
      }
    }

    return Material(
      child: Column(
        children: [
          ListTile(
            leading: BackButton(onPressed: onBack),
            title: const Text('買い物リスト'),
            subtitle: Text(groupName),
            trailing: TextButton(
              onPressed: () => _showHistory(context, groupId),
              child: const Text('購入履歴'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: '品物名'),
                    textInputAction: TextInputAction.next,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: quantity,
                    decoration: const InputDecoration(labelText: '数量'),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    onSubmitted: (_) => add(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: canAdd ? add : null,
                  child: const Text('追加'),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.unchecked.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: notifier.watchUnchecked,
                  child: const Text('買い物リストを取得できませんでした。再試行'),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('未チェックの品物はありません'))
                  : ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: items.length,
                      itemBuilder: (_, index) {
                        final item = items[index];
                        return _ShoppingItemRow(
                          key: ValueKey(item.id),
                          item: item,
                          enabled: !state.saving,
                          onEdit: (expected, name, quantity) => _save(
                            context,
                            () => notifier.edit(expected, name, quantity),
                            retry: false,
                          ),
                          onCheck: () => _save(context, () async {
                            final purchased = await notifier.check(item);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${purchased.name}を購入履歴に追加しました'),
                                action: SnackBarAction(
                                  label: '元に戻す',
                                  onPressed: () => _save(
                                    context,
                                    () => notifier.undoCheck(
                                      purchased,
                                      item.purchasedAt,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          onDelete: () async {
                            if (await _confirmDelete(context, item.name) &&
                                context.mounted) {
                              await _save(context, () => notifier.delete(item));
                            }
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShoppingItemRow extends StatefulWidget {
  const _ShoppingItemRow({
    super.key,
    required this.item,
    required this.enabled,
    required this.onEdit,
    required this.onCheck,
    required this.onDelete,
  });

  final ShoppingListItemDto item;
  final bool enabled;
  final Future<bool> Function(ShoppingListItemDto, String, String) onEdit;
  final VoidCallback onCheck;
  final VoidCallback onDelete;

  @override
  State<_ShoppingItemRow> createState() => _ShoppingItemRowState();
}

class _ShoppingItemRowState extends State<_ShoppingItemRow> {
  late final _name = TextEditingController(text: widget.item.name);
  late final _quantity = TextEditingController(text: widget.item.quantity);
  final _focus = FocusScopeNode();
  ShoppingListItemDto? _editing;
  bool _saving = false;

  bool get _changed {
    final base = _editing ?? widget.item;
    return _name.text.trim() != base.name ||
        _quantity.text.trim() != base.quantity;
  }

  @override
  void didUpdateWidget(covariant _ShoppingItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_editing == null && oldWidget.item.version != widget.item.version) {
      _reset();
    }
  }

  void _reset() {
    _name.text = widget.item.name;
    _quantity.text = widget.item.quantity;
  }

  void _focusChanged(bool focused) {
    if (focused) {
      _editing ??= widget.item;
    } else {
      _saveDraft();
    }
  }

  Future<void> _saveDraft() async {
    final expected = _editing;
    if (expected == null || _saving) return;
    if (!_changed) {
      setState(() {
        _editing = null;
        _reset();
      });
      return;
    }
    setState(() => _saving = true);
    final saved = await widget.onEdit(expected, _name.text, _quantity.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved || expected.version != widget.item.version) {
        _editing = null;
        if (!saved) _reset();
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canAct = widget.enabled && !_saving && !_changed;
    return TextFieldTapRegion(
      child: FocusScope(
        node: _focus,
        onFocusChange: _focusChanged,
        child: Row(
          children: [
            Checkbox(
              semanticLabel: '${widget.item.name}を購入済みにする',
              value: false,
              onChanged: canAct ? (_) => widget.onCheck() : null,
            ),
            Expanded(flex: 3, child: _field(_name, '品物名')),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: _field(_quantity, '数量')),
            if (_changed && !_focus.hasFocus && !_saving)
              IconButton(
                tooltip: '編集を再試行',
                onPressed: widget.enabled ? _saveDraft : null,
                icon: const Icon(Icons.save),
              )
            else
              IconButton(
                tooltip: '品物を削除',
                onPressed: canAct ? widget.onDelete : null,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint) => TextField(
    controller: controller,
    readOnly: _saving,
    decoration: InputDecoration(hintText: hint),
    onTapOutside: (_) => _focus.unfocus(),
    onSubmitted: (_) {
      _focus.unfocus();
      _saveDraft();
    },
    onChanged: (_) => setState(() {}),
  );
}

Future<bool> _save(
  BuildContext context,
  Future<void> Function() action, {
  bool retry = true,
  bool modal = false,
}) async {
  try {
    await action();
    return true;
  } catch (_) {
    if (!context.mounted) return false;
    if (modal) {
      final again = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text('保存できませんでした。品物の内容を確認してください'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('閉じる'),
            ),
            if (retry)
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('再試行'),
              ),
          ],
        ),
      );
      if (again == true && context.mounted) {
        return _save(context, action, modal: true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('保存できませんでした。品物の内容を確認してください'),
          action: retry
              ? SnackBarAction(
                  label: '再試行',
                  onPressed: () => _save(context, action),
                )
              : null,
        ),
      );
    }
    return false;
  }
}

Future<bool> _confirmDelete(BuildContext context, String name) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text(name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    ) ??
    false;

Future<bool> _editExistingQuantity(
  BuildContext context,
  ShoppingListNotifier notifier,
  ShoppingListItemDto item,
  String initialQuantity, {
  bool modal = false,
}) async {
  final quantity = await showDialog<String>(
    context: context,
    builder: (context) => _QuantityDialog(
      item: item,
      initialQuantity: initialQuantity.isEmpty
          ? item.quantity
          : initialQuantity,
    ),
  );
  if (quantity == null || !context.mounted) return false;
  if (quantity == item.quantity) return true;
  return _save(
    context,
    () => notifier.edit(item, item.name, quantity),
    modal: modal,
  );
}

class _QuantityDialog extends HookWidget {
  const _QuantityDialog({required this.item, required this.initialQuantity});

  final ShoppingListItemDto item;
  final String initialQuantity;

  @override
  Widget build(BuildContext context) {
    final quantity = useTextEditingController(text: initialQuantity);
    return AlertDialog(
      title: Text('${item.name}は追加済みです'),
      content: TextField(
        controller: quantity,
        decoration: const InputDecoration(labelText: '数量'),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, quantity.text),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

Future<void> _showHistory(BuildContext context, String groupId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: _ShoppingHistory(groupId: groupId),
      ),
    );

class _ShoppingHistory extends HookConsumerWidget {
  const _ShoppingHistory({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = shoppingListNotifierProvider(groupId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final history = state.history;
    final message = useState<String?>(null);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) notifier.loadHistory(refresh: true);
      });
      return null;
    }, [notifier]);

    return SafeArea(
      top: false,
      child: Column(
        children: [
          ListTile(title: const Text('購入履歴'), trailing: const CloseButton()),
          if (message.value != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Semantics(liveRegion: true, child: Text(message.value!)),
            ),
          Expanded(
            child: ListView(
              children: [
                for (final item in history.items)
                  ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      MaterialLocalizations.of(context)
                          .formatCompactDate(item.purchasedAt!.toLocal()),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: state.saving || !state.unchecked.hasValue
                              ? null
                              : () async {
                                  final existing = state.unchecked.requireValue
                                      .where((entry) => entry.name == item.name)
                                      .firstOrNull;
                                  final saved = existing == null
                                      ? await _save(
                                          context,
                                          () => notifier.add(item.name, ''),
                                          modal: true,
                                        )
                                      : await _editExistingQuantity(
                                          context,
                                          notifier,
                                          existing,
                                          '',
                                          modal: true,
                                        );
                                  if (saved && context.mounted) {
                                    if (existing == null) {
                                      message.value =
                                          '${item.name}を買い物リストに追加しました';
                                    }
                                    await notifier.loadHistory(refresh: true);
                                  }
                                },
                          child: const Text('再登録'),
                        ),
                        IconButton(
                          tooltip: '購入履歴を削除',
                          onPressed: state.saving
                              ? null
                              : () async {
                                  if (await _confirmDelete(
                                        context,
                                        item.name,
                                      ) &&
                                      context.mounted) {
                                    await _save(
                                      context,
                                      () => notifier.deleteHistory(item),
                                      modal: true,
                                    );
                                  }
                                },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                if (history.loading)
                  const Center(child: CircularProgressIndicator())
                else if (history.hasError || history.next != null)
                  TextButton(
                    onPressed: notifier.loadHistory,
                    child: Text(history.hasError ? '取得できませんでした。再試行' : 'さらに表示'),
                  )
                else if (history.items.isEmpty)
                  const ListTile(title: Text('購入履歴はありません')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
