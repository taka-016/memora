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
    return _DurationInput(minutes: value.minutes);
  }
}

class _DurationInput extends ConsumerStatefulWidget {
  const _DurationInput({required this.minutes});

  final int minutes;

  @override
  ConsumerState<_DurationInput> createState() => _DurationInputState();
}

class _DurationInputState extends ConsumerState<_DurationInput>
    with WidgetsBindingObserver {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  bool _isInvalid = false;
  late bool _isCustom;
  bool _keyboardWasVisible = false;
  static const _presetMinutes = [5, 15, 30, 45, 60];

  bool _isPreset(int minutes) => _presetMinutes.contains(minutes);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = TextEditingController(text: '${widget.minutes}');
    _isCustom = !_isPreset(widget.minutes);
  }

  @override
  void didUpdateWidget(_DurationInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minutes != widget.minutes && !_focusNode.hasFocus) {
      _controller.text = '${widget.minutes}';
      _isInvalid = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _keyboardWasVisible = View.of(context).viewInsets.bottom > 0;
  }

  @override
  void reassemble() {
    super.reassemble();
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);
    _keyboardWasVisible = View.of(context).viewInsets.bottom > 0;
  }

  @override
  void didChangeMetrics() {
    final keyboardIsVisible = View.of(context).viewInsets.bottom > 0;
    final keyboardWasDismissed = _keyboardWasVisible && !keyboardIsVisible;
    _keyboardWasVisible = keyboardIsVisible;
    if (!keyboardWasDismissed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && View.of(context).viewInsets.bottom == 0) {
        _focusNode.unfocus();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('予定の標準時間'),
        trailing: DropdownButton<int>(
          value: _isCustom || !_isPreset(widget.minutes) ? 0 : widget.minutes,
          items: [
            for (final minutes in _presetMinutes)
              DropdownMenuItem(value: minutes, child: Text('$minutes分')),
            const DropdownMenuItem(value: 0, child: Text('その他')),
          ],
          onChanged: _select,
        ),
      ),
      if (_isCustom || !_isPreset(widget.minutes))
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 80,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                suffixText: '分',
                isDense: true,
                errorText: _isInvalid ? '1〜1440分' : null,
              ),
              onChanged: _save,
              onSubmitted: (_) => _focusNode.unfocus(),
              onTapOutside: (_) => _focusNode.unfocus(),
            ),
          ),
        ),
    ],
  );

  Future<void> _select(int? minutes) async {
    if (minutes == null) return;
    _focusNode.unfocus();
    setState(() {
      _isCustom = minutes == 0;
      _isInvalid = false;
    });
    if (minutes == 0) return;
    await _persist(minutes);
  }

  Future<void> _save(String text) async {
    final minutes = int.tryParse(text);
    final isInvalid = minutes == null || minutes < 1 || minutes > 1440;
    setState(() => _isInvalid = isInvalid);
    if (isInvalid) return;
    await _persist(minutes);
  }

  Future<void> _persist(int minutes) async {
    final success = await ref
        .read(calendarPreferencesNotifierProvider.notifier)
        .save(minutes);
    if (!mounted || success) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('予定の標準時間を保存できませんでした')));
  }
}
