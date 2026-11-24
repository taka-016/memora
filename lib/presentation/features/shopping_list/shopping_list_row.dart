import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/shopping_list/shopping_list_item.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/shopping_list_providers.dart';

class ShoppingListRow extends ConsumerStatefulWidget {
  const ShoppingListRow({
    super.key,
    required this.groupId,
    required this.item,
    required this.isChecking,
    required this.onCheck,
  });

  final String groupId;
  final ShoppingListItem item;
  final bool isChecking;
  final ValueChanged<ShoppingListItem> onCheck;

  @override
  ConsumerState<ShoppingListRow> createState() => _ShoppingListRowState();
}

class _ShoppingListRowState extends ConsumerState<ShoppingListRow> {
  late ShoppingListItem _original = widget.item;
  late final _name = TextEditingController(text: _original.name);
  late final _quantity = TextEditingController(text: _original.pendingQuantity);
  final _nameFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _tapRegion = Object();
  bool _isSaving = false;
  bool _awaitingUpdate = false;
  String? _message;

  bool get _hasChanges =>
      _name.text.trim() != _original.name ||
      _quantity.text.trim() != _original.pendingQuantity;

  @override
  void didUpdateWidget(ShoppingListRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSaving &&
        widget.item.version > _original.version &&
        (_awaitingUpdate || !_hasChanges)) {
      _load(widget.item);
    }
  }

  void _load(ShoppingListItem item) {
    _original = item;
    if (_name.text != item.name) _name.text = item.name;
    final quantity = item.pendingQuantity!;
    if (_quantity.text != quantity) _quantity.text = quantity;
    _awaitingUpdate = false;
    _message = null;
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _quantityFocus.dispose();
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!mounted || _isSaving || _awaitingUpdate || !_hasChanges) return;

    final list = ref.read(shoppingListProvider);
    setState(() {
      _isSaving = true;
      _message = null;
    });
    try {
      final duplicate = await list.edit(
        widget.groupId,
        _original,
        _name.text,
        _quantity.text,
      );
      if (!mounted) return;
      if (duplicate != null) {
        _message = '同じ品物名が一覧にあります。';
      } else if (widget.item.version > _original.version) {
        _load(widget.item);
      } else {
        _awaitingUpdate = true;
      }
    } catch (error) {
      if (mounted) {
        _message = error is ApplicationValidationException
            ? error.message
            : '変更を保存できませんでした。再試行してください。';
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isSaving || _awaitingUpdate || widget.isChecking;
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) unawaited(_save());
      },
      child: ListTile(
        leading: Checkbox(
          value: false,
          semanticLabel: '${_original.name}を購入済みにする',
          onChanged: busy || _hasChanges
              ? null
              : (_) => widget.onCheck(_original),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildField(
                    controller: _name,
                    focusNode: _nameFocus,
                    label: '品物名',
                    enabled: !busy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _quantity,
                    focusNode: _quantityFocus,
                    label: '数量',
                    hint: '数量を入力',
                    enabled: !busy,
                  ),
                ),
              ],
            ),
            if (_message case final message?)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextFieldTapRegion(
                    groupId: _tapRegion,
                    child: TextButton(
                      onPressed: () => setState(() => _load(widget.item)),
                      child: const Text('入力を取り消す'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool enabled,
    String? hint,
  }) => Semantics(
    label: label,
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      groupId: _tapRegion,
      enabled: enabled,
      textInputAction: TextInputAction.done,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _save(),
      onTapOutside: (_) {
        focusNode.unfocus();
        unawaited(_save());
      },
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        border: InputBorder.none,
        focusedBorder: const UnderlineInputBorder(),
      ),
    ),
  );
}
