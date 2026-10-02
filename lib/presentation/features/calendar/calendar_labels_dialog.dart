import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          child: ListView(
            children: [
              if (state.labels.isEmpty)
                const Text('家族の名前や「家族全員」などのラベルを追加してください'),
              for (final label in state.labels)
                ListTile(
                  leading: Icon(
                    Icons.circle,
                    color: calendarLabelColor(label.color),
                  ),
                  title: Text(label.name),
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
                                .deleteLabel(label.id);
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
  late final TextEditingController _color;
  String _error = '';
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.label?.name ?? '');
    _color = TextEditingController(text: widget.label?.color ?? '#2196F3');
  }

  @override
  void dispose() {
    _name.dispose();
    _color.dispose();
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
                TextFormField(
                  controller: _name,
                  enabled: !saving,
                  decoration: const InputDecoration(labelText: '名前'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? '名前を入力してください'
                      : null,
                ),
                TextFormField(
                  controller: _color,
                  enabled: !saving,
                  decoration: const InputDecoration(
                    labelText: '色（#RRGGBB）',
                    helperText: '例: #2196F3',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) =>
                      !RegExp(r'^#[0-9a-fA-F]{6}$')
                          .hasMatch(value?.trim() ?? '')
                      ? '#RRGGBB形式で入力してください'
                      : null,
                ),
                if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(_color.text.trim()))
                  Icon(
                    Icons.circle,
                    semanticLabel: '選択した色',
                    color: calendarLabelColor(_color.text.trim()),
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
                            id: widget.label?.id ?? '',
                            groupId: widget.groupId,
                            name: _name.text.trim(),
                            color: _color.text.trim(),
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
