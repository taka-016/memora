import 'package:memora/presentation/helpers/date_picker_helper.dart';
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
          if (start.weekday <= DateTime.friday) 'weekdays': '平日（月〜金）',
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
  if (choice != 'custom') {
    return CalendarRecurrenceSettings.preset(choice, start);
  }
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
  late Set<int> _weekdays;
  late int _monthlyDay;
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
    _weekdays = {...value.weekdays, widget.start.weekday};
    final lastDay = DateTime(widget.start.year, widget.start.month + 1, 0).day;
    final requested = value.monthDay ?? widget.start.day;
    _monthlyDay = (requested > lastDay ? lastDay : requested) == widget.start.day ? requested : widget.start.day;
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
    super.dispose();
  }

  String? _positive(String? value) =>
      (int.tryParse(value ?? '') ?? 0) > 0 ? null : '1以上の整数を入力してください';
  void _confirm() {
    if (!_form.currentState!.validate()) return;
    if (_endMode == 'until' &&
        DateTime(_until.year, _until.month, _until.day).isBefore(
          DateTime(widget.start.year, widget.start.month, widget.start.day),
        )) {
      setState(() => _error = '終了日は開始日以降にしてください');
      return;
    }
    Navigator.pop(
      context,
      CalendarRecurrenceSettings(
        frequency: _frequency,
        interval: int.parse(_interval.text),
        weekdays: _frequency == 'WEEKLY' ? (_weekdays.toList()..sort()) : [],
        monthDay: _frequency == 'MONTHLY' ? _monthlyDay : null,
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
                        onSelected: day == widget.start.weekday
                            ? null
                            : (selected) => setState(() {
                                if (selected) {
                                  _weekdays.add(day);
                                } else {
                                  _weekdays.remove(day);
                                }
                              }),
                      ),
                  ],
                ),
              if (_frequency == 'MONTHLY') Text('毎月$_monthlyDay日'),
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
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                  onPressed: () async {
                    final date = await DatePickerHelper.showCustomDatePicker(
                      context,
                      initialDate: DateTime(
                        (_until.isBefore(widget.start) ? widget.start : _until)
                            .year,
                        (_until.isBefore(widget.start) ? widget.start : _until)
                            .month,
                        (_until.isBefore(widget.start) ? widget.start : _until)
                            .day,
                      ),
                      firstDate: DateTime(
                        widget.start.year,
                        widget.start.month,
                        widget.start.day,
                      ),
                      lastDate: DateTime(9999, 12, 31),
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
