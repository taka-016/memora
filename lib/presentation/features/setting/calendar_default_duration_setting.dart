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
    return _DurationForm(minutes: value.minutes, isSaving: value.isSaving);
  }
}

class _DurationForm extends ConsumerStatefulWidget {
  const _DurationForm({required this.minutes, required this.isSaving});

  final int minutes;
  final bool isSaving;

  @override
  ConsumerState<_DurationForm> createState() => _DurationFormState();
}

class _DurationFormState extends ConsumerState<_DurationForm> {
  final _form = GlobalKey<FormState>();
  final _field = GlobalKey<FormFieldState<String>>();

  @override
  void didUpdateWidget(_DurationForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minutes != widget.minutes) {
      _field.currentState?.didChange('${widget.minutes}');
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: _field,
          initialValue: '${widget.minutes}',
          enabled: !widget.isSaving,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '予定の標準時間',
            suffixText: '分',
            helperText: '1〜1440分',
            border: OutlineInputBorder(),
          ),
          validator: (text) {
            final minutes = int.tryParse(text ?? '');
            return minutes == null || minutes < 1 || minutes > 1440
                ? '1〜1440分で指定してください'
                : null;
          },
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: widget.isSaving ? null : _save,
          child: const Text('保存'),
        ),
      ],
    ),
  );

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final success = await ref
        .read(calendarPreferencesNotifierProvider.notifier)
        .save(int.parse(_field.currentState!.value!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '予定の標準時間を保存しました' : '予定の標準時間を保存できませんでした'),
      ),
    );
  }
}
