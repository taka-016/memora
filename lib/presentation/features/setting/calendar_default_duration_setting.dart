import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_preferences_notifier.dart';

class CalendarDefaultDurationSetting extends ConsumerWidget {
  const CalendarDefaultDurationSetting({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(calendarPreferencesNotifierProvider);
    final value = setting.value;
    if (value == null) {
      if (setting.hasError) {
        return TextButton(
          onPressed: () => ref.invalidate(calendarPreferencesNotifierProvider),
          child: const Text('予定の標準時間を再取得'),
        );
      }
      return const LinearProgressIndicator();
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('予定の標準時間'),
      subtitle: Text('${value.minutes}分'),
      trailing: const Icon(Icons.edit),
      onTap: value.isSaving
          ? null
          : () async {
              final minutes = await showDialog<int>(
                context: context,
                builder: (context) => _DurationDialog(minutes: value.minutes),
              );
              if (minutes == null || !context.mounted) return;
              final success = await ref
                  .read(calendarPreferencesNotifierProvider.notifier)
                  .save(minutes);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? '予定の標準時間を保存しました' : '予定の標準時間を保存できませんでした',
                  ),
                ),
              );
            },
    );
  }
}

class _DurationDialog extends StatefulWidget {
  const _DurationDialog({required this.minutes});
  final int minutes;
  @override
  State<_DurationDialog> createState() => _DurationDialogState();
}

class _DurationDialogState extends State<_DurationDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.minutes}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('予定の標準時間'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: '分',
          helperText: '1〜1440分',
        ),
        validator: (text) {
          final minutes = int.tryParse(text ?? '');
          return minutes == null || minutes < 1 || minutes > 1440
              ? '1〜1440分で指定してください'
              : null;
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('キャンセル'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, int.parse(_controller.text));
          }
        },
        child: const Text('保存'),
      ),
    ],
  );
}
