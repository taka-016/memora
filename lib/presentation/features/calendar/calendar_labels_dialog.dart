import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/shared/inputs/label_color_settings.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';

Color calendarLabelColor(String color) =>
    Color(0xFF000000 | int.parse(color.substring(1), radix: 16));

class CalendarLabelsDialog extends ConsumerWidget {
  const CalendarLabelsDialog({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarNotifierProvider(groupId));
    final canReorder =
        !state.isSaving && !state.isLoading && state.loadError.isEmpty;
    Future<void> edit([CalendarLabelDto? label]) async {
      await showDialog<void>(
        context: context,
        builder: (context) => _LabelEditDialog(groupId: groupId, label: label),
      );
    }

    return PopScope(
      canPop: !state.isSaving,
      child: AlertDialog(
        title: const Text('色ラベルの設定'),
        content: SizedBox(
          width: 420,
          height: 320,
          child: ReorderableListView(
            buildDefaultDragHandles: false,
            onReorderItem: (oldIndex, newIndex) async {
              if (!canReorder) return;
              final success = await ref
                  .read(calendarNotifierProvider(groupId).notifier)
                  .reorderLabels(oldIndex, newIndex);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ref.read(calendarNotifierProvider(groupId)).mutationError,
                    ),
                  ),
                );
              }
            },
            children: [
              if (state.labels.isEmpty)
                const Text(
                  '用途に合わせたラベルを追加できます。',
                  key: Key('calendar_labels_empty'),
                ),
              for (final (index, label) in state.labels.indexed)
                ListTile(
                  key: ValueKey(label.id),
                  leading: ReorderableDragStartListener(
                    key: Key('calendar_label_drag_${label.id}'),
                    index: index,
                    enabled: canReorder,
                    child: Semantics(
                      label: 'ラベルの並び替え',
                      child: Container(
                        width: kMinInteractiveDimension,
                        height: kMinInteractiveDimension,
                        alignment: Alignment.center,
                        color: Colors.transparent,
                        child: Icon(
                          Icons.drag_handle,
                          color: canReorder
                              ? null
                              : Theme.of(context).disabledColor,
                        ),
                      ),
                    ),
                  ),
                  title: ReorderableDelayedDragStartListener(
                    index: index,
                    enabled: canReorder,
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: kMinInteractiveDimension,
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: calendarLabelColor(label.color),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label.name,
                        style: TextStyle(
                          color: calendarLabelColor(label.textColor),
                        ),
                      ),
                    ),
                  ),
                  onTap: state.isSaving ? null : () => edit(label),
                  trailing: IconButton(
                    tooltip: '色ラベルを削除',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: state.isSaving
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('色ラベルを削除'),
                                content: Text('「${label.name}」を削除しますか？'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('キャンセル'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('削除する'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            final success = await ref
                                .read(
                                  calendarNotifierProvider(groupId).notifier,
                                )
                                .deleteLabel(
                                  label.id,
                                  expectedVersion: label.version,
                                );
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ref
                                        .read(calendarNotifierProvider(groupId))
                                        .mutationError,
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: state.isSaving ? null : () => edit(),
            child: const Text('ラベルを追加'),
          ),
          TextButton(
            onPressed: state.isSaving ? null : () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

class _LabelEditDialog extends ConsumerStatefulWidget {
  const _LabelEditDialog({required this.groupId, this.label});
  final String groupId;
  final CalendarLabelDto? label;
  @override
  ConsumerState<_LabelEditDialog> createState() => _LabelEditDialogState();
}

class _LabelEditDialogState extends ConsumerState<_LabelEditDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _color;
  late final int _sortOrder;
  String _error = '';
  late String _textColor;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.label?.name ?? '');
    final labels = ref.read(calendarNotifierProvider(widget.groupId)).labels;
    final nextOrder =
        labels.fold(
          0,
          (order, label) => label.sortOrder > order ? label.sortOrder : order,
        ) +
        1;
    _sortOrder = widget.label?.sortOrder ?? nextOrder;
    _color = widget.label?.color ?? '#2196F3';
    _textColor = widget.label?.textColor ?? '#FFFFFF';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(calendarNotifierProvider(widget.groupId)).isSaving;
    return PopScope(
      canPop: !saving,
      child: AlertDialog(
        title: Text(widget.label == null ? 'ラベルを追加' : 'ラベルを編集'),
        content: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.label == null) ...[
                  const Text('グループ・メンバーの色は「グループ管理」で設定できます。'),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _name,
                  enabled: !saving,
                  decoration: const InputDecoration(labelText: '名前'),
                  onChanged: (_) => setState(() {}),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? '名前を入力してください'
                      : null,
                ),
                const SizedBox(height: 16),
                LabelColorSettings(
                  label: _name.text.trim().isEmpty ? 'ラベル名' : _name.text.trim(),
                  color: _color,
                  textColor: _textColor,
                  enabled: !saving,
                  allDayPreviewKey: const Key('calendar_label_preview'),
                  timedPreviewKey: const Key('calendar_label_timed_preview'),
                  onChanged: (color, textColor) => setState(() {
                    _color = color;
                    _textColor = textColor!;
                  }),
                ),
                if (_error.isNotEmpty) Text(_error),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    if (!_form.currentState!.validate()) return;
                    final success = await ref
                        .read(calendarNotifierProvider(widget.groupId).notifier)
                        .saveLabel(
                          CalendarLabelDto(
                            version: widget.label?.version,
                            id: widget.label?.id ?? '',
                            groupId: widget.groupId,
                            name: _name.text.trim(),
                            color: _color.trim(),
                            textColor: _textColor,
                            sortOrder: _sortOrder,
                          ),
                        );
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.pop(context);
                    } else {
                      setState(
                        () => _error = ref
                            .read(calendarNotifierProvider(widget.groupId))
                            .mutationError,
                      );
                    }
                  },
            child: Text(saving ? '保存中' : '保存'),
          ),
        ],
      ),
    );
  }
}
