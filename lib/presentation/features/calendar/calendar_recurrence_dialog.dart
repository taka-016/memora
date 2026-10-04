import 'package:flutter/material.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_settings.dart';

Future<CalendarRecurrenceSettings?> showCalendarRecurrencePicker(
  BuildContext context,
  CalendarRecurrenceSettings current,
  DateTime start,
) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('繰り返し'),
      children: [
        for (final entry in {
          'none': '繰り返さない',
          'daily': '毎日',
          'weekly':
              '毎週（${CalendarRecurrenceSettings.dayNames[start.weekday - 1]}曜日）',
          'monthly': '毎月',
          'yearly': '毎年',
          'weekdays': '平日（月〜金）',
          'custom': 'カスタム',
        }.entries)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, entry.key),
            child: Text(entry.value),
          ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return null;
  if (choice != 'custom')
    return CalendarRecurrenceSettings.preset(choice, start);
  return showDialog<CalendarRecurrenceSettings>(
    context: context,
    builder: (_) =>
        CalendarRecurrenceCustomDialog(settings: current, start: start),
  );
}

class CalendarRecurrenceCustomDialog extends StatefulWidget {
  const CalendarRecurrenceCustomDialog({
    super.key,
    required this.settings,
    required this.start,
  });
  final CalendarRecurrenceSettings settings;
  final DateTime start;
  @override
  State<CalendarRecurrenceCustomDialog> createState() =>
      _CalendarRecurrenceCustomDialogState();
}

class _CalendarRecurrenceCustomDialogState
    extends State<CalendarRecurrenceCustomDialog> {
  final _form = GlobalKey<FormState>();
  late String _frequency;
  late final TextEditingController _interval;
  late final TextEditingController _count;
  late final TextEditingController _monthDay;
  late Set<int> _weekdays;
  late int _weekday;
  late int _ordinal;
  late String _monthlyMode;
  late String _endMode;
  late DateTime _until;
  String _error = '';
  @override
  void initState() {
    super.initState();
    final value = widget.settings;
    _frequency = value.frequency ?? 'WEEKLY';
    _interval = TextEditingController(text: '${value.interval}');
    _count = TextEditingController(text: '${value.count ?? 10}');
    _monthDay = TextEditingController(
      text: '${value.monthDay ?? widget.start.day}',
    );
    _weekdays = value.weekdays.toSet();
    _weekday = value.weekdays.firstOrNull ?? widget.start.weekday;
    _ordinal = value.ordinal ?? (widget.start.day - 1) ~/ 7 + 1;
    _monthlyMode = value.ordinal == null ? 'date' : 'weekday';
    _endMode = value.count != null
        ? 'count'
        : value.until != null
        ? 'until'
        : 'never';
    _until = value.until ?? widget.start;
  }

  @override
  void dispose() {
    _interval.dispose();
    _count.dispose();
    _monthDay.dispose();
    super.dispose();
  }

  String? _positive(String? value) =>
      (int.tryParse(value ?? '') ?? 0) > 0 ? null : '1以上の整数を入力してください';
  void _confirm() {
    if (!_form.currentState!.validate()) return;
    if (_frequency == 'WEEKLY' && _weekdays.isEmpty) {
      setState(() => _error = '曜日を選択してください');
      return;
    }
    Navigator.pop(
      context,
      CalendarRecurrenceSettings(
        frequency: _frequency,
        interval: int.parse(_interval.text),
        weekdays: _frequency == 'WEEKLY'
            ? (_weekdays.toList()..sort())
            : _frequency == 'MONTHLY' && _monthlyMode == 'weekday'
            ? [_weekday]
            : [],
        monthDay: _frequency == 'MONTHLY' && _monthlyMode == 'date'
            ? int.parse(_monthDay.text)
            : null,
        ordinal: _frequency == 'MONTHLY' && _monthlyMode == 'weekday'
            ? _ordinal
            : null,
        count: _endMode == 'count' ? int.parse(_count.text) : null,
        until: _endMode == 'until' ? _until : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('カスタムの繰り返し'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: '単位'),
                items: [
                  for (final entry in {
                    'DAILY': '日',
                    'WEEKLY': '週',
                    'MONTHLY': '月',
                    'YEARLY': '年',
                  }.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: (value) => setState(() => _frequency = value!),
              ),
              TextFormField(
                controller: _interval,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '間隔'),
                validator: _positive,
              ),
              if (_frequency == 'WEEKLY')
                Wrap(
                  spacing: 4,
                  children: [
                    for (var day = 1; day <= 7; day++)
                      FilterChip(
                        label: Text(
                          CalendarRecurrenceSettings.dayNames[day - 1],
                        ),
                        selected: _weekdays.contains(day),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _weekdays.add(day);
                          } else {
                            _weekdays.remove(day);
                          }
                        }),
                      ),
                  ],
                ),
              if (_frequency == 'MONTHLY') ...[
                DropdownButtonFormField<String>(
                  initialValue: _monthlyMode,
                  decoration: const InputDecoration(labelText: '月の指定方法'),
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('日付指定')),
                    DropdownMenuItem(value: 'weekday', child: Text('曜日指定')),
                  ],
                  onChanged: (value) => setState(() => _monthlyMode = value!),
                ),
                if (_monthlyMode == 'date')
                  TextFormField(
                    controller: _monthDay,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '日付'),
                    validator: (value) =>
                        (int.tryParse(value ?? '') ?? 0) >= 1 &&
                            (int.tryParse(value ?? '') ?? 0) <= 31
                        ? null
                        : '1〜31を入力してください',
                  ),
                if (_monthlyMode == 'weekday') ...[
                  DropdownButtonFormField<int>(
                    initialValue: _ordinal,
                    decoration: const InputDecoration(labelText: '週の指定'),
                    items: [
                      for (final n in [1, 2, 3, 4, 5, -1])
                        DropdownMenuItem(
                          value: n,
                          child: Text(n == -1 ? '最終' : '第$n'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _ordinal = value!),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: _weekday,
                    decoration: const InputDecoration(labelText: '曜日'),
                    items: [
                      for (var day = 1; day <= 7; day++)
                        DropdownMenuItem(
                          value: day,
                          child: Text(
                            '${CalendarRecurrenceSettings.dayNames[day - 1]}曜日',
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _weekday = value!),
                  ),
                ],
              ],
              DropdownButtonFormField<String>(
                initialValue: _endMode,
                decoration: const InputDecoration(labelText: '終了条件'),
                items: const [
                  DropdownMenuItem(value: 'never', child: Text('終了しない')),
                  DropdownMenuItem(value: 'count', child: Text('回数指定')),
                  DropdownMenuItem(value: 'until', child: Text('終了日指定')),
                ],
                onChanged: (value) => setState(() => _endMode = value!),
              ),
              if (_endMode == 'count')
                TextFormField(
                  controller: _count,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '回数'),
                  validator: _positive,
                ),
              if (_endMode == 'until')
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _until,
                      firstDate: DateTime(1),
                      lastDate: DateTime(9999, 12, 31),
                      helpText: '繰り返しの終了日',
                      cancelText: 'キャンセル',
                      confirmText: '決定',
                    );
                    if (date != null && mounted) setState(() => _until = date);
                  },
                  child: Text(
                    '終了日: ${_until.year}/${_until.month}/${_until.day}',
                  ),
                ),
              if (_error.isNotEmpty)
                Text(
                  _error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('キャンセル'),
      ),
      FilledButton(onPressed: _confirm, child: const Text('決定')),
    ],
  );
}
