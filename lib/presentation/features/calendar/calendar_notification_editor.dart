import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';

String calendarNotificationText(int value, bool allDay) {
  if (value == 0) return '予定の開始時';
  if (value % 10080 == 0) return '${value ~/ 10080}週間前';
  if (value % 1440 == 0) return '${value ~/ 1440}日前';
  return value % 60 == 0 ? '${value ~/ 60}時間前' : '$value分前';
}

class CalendarNotificationEditor extends StatelessWidget {
  const CalendarNotificationEditor({
    super.key,
    required this.allDay,
    required this.values,
    required this.onChanged,
    this.enabled = true,
  });
  final bool allDay;
  final List<int> values;
  final ValueChanged<List<int>> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('通知'),
    subtitle: Text(
      values.isEmpty
          ? '通知なし'
          : (List.of(values)..sort())
                .map((value) => calendarNotificationText(value, allDay))
                .join('、'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: const Icon(Icons.chevron_right),
    enabled: enabled,
    onTap: !enabled
        ? null
        : () async {
            final selected = await showDialog<List<int>>(
              context: context,
              builder: (_) =>
                  _CalendarNotificationDialog(allDay: allDay, values: values),
            );
            if (selected != null) onChanged(selected);
          },
  );
}

class _CalendarNotificationDialog extends StatefulWidget {
  const _CalendarNotificationDialog({
    required this.allDay,
    required this.values,
  });
  final bool allDay;
  final List<int> values;

  @override
  State<_CalendarNotificationDialog> createState() =>
      _CalendarNotificationDialogState();
}

class _CalendarNotificationDialogState
    extends State<_CalendarNotificationDialog> {
  final _number = TextEditingController();
  late final Set<int> _selected;
  late final Set<int> _choices;
  late int _unit;
  String? _error;

  int get _maxMinutes => widget.allDay
      ? MAX_ALL_DAY_CALENDAR_NOTIFICATION_MINUTES
      : MAX_TIMED_CALENDAR_NOTIFICATION_MINUTES;

  String get _limitText =>
      widget.allDay ? '終日の通知は4週間前まで指定できます' : '時間指定の通知は1週間前まで指定できます';

  Map<int, String> get _units => {
    if (!widget.allDay) ...{1: '分前', 60: '時間前'},
    1440: '日前',
    10080: '週間前',
  };

  @override
  void initState() {
    super.initState();
    _selected = widget.values.toSet();
    _choices = {
      ...widget.allDay
          ? [0, 1440, 2880, 10080, 20160, 40320]
          : [0, 5, 10, 15, 30, 60, 120, 180, 1440, 10080],
      ..._selected,
    };
    _unit = widget.allDay ? 1440 : 1;
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  void _addCustom() {
    final number = int.tryParse(_number.text);
    if (number == null || number < 0) {
      setState(() => _error = '0以上の整数を入力してください');
      return;
    }
    if (number > _maxMinutes ~/ _unit) {
      setState(() => _error = _limitText);
      return;
    }
    final minutes = number * _unit;
    if (!_selected.contains(minutes) &&
        _selected.length >= MAX_CALENDAR_NOTIFICATIONS) {
      setState(() => _error = '通知は最大$MAX_CALENDAR_NOTIFICATIONS件です');
      return;
    }
    setState(() {
      _selected.add(minutes);
      _choices.add(minutes);
      _error = null;
      _number.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final choices = _choices.toList()..sort();
    final atLimit = _selected.length >= MAX_CALENDAR_NOTIFICATIONS;
    return AlertDialog(
      title: const Text('通知のタイミング'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('選択中 ${_selected.length}/$MAX_CALENDAR_NOTIFICATIONS件'),
              Text(_limitText),
              for (final value in choices)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(calendarNotificationText(value, widget.allDay)),
                  value: _selected.contains(value),
                  onChanged:
                      (atLimit || value > _maxMinutes) &&
                          !_selected.contains(value)
                      ? null
                      : (checked) => setState(() {
                          if (checked == true) {
                            _selected.add(value);
                          } else {
                            _selected.remove(value);
                          }
                          _error = null;
                        }),
                ),
              const Divider(),
              const Text('タイミングを指定して追加'),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _number,
                      enabled: !atLimit,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '数値',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addCustom(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _unit,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '単位',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final entry in _units.entries)
                          DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                      ],
                      onChanged: atLimit
                          ? null
                          : (value) => setState(() => _unit = value!),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: atLimit ? null : _addCustom,
                  child: const Text('追加'),
                ),
              ),
              if (atLimit) const Text('上限に達しました。変更する場合は選択を解除してください'),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            _selected.clear();
            _error = null;
          }),
          child: const Text('通知なし'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _selected.any((value) => value > _maxMinutes)
              ? null
              : () => Navigator.pop(context, _selected.toList()..sort()),
          child: const Text('決定'),
        ),
      ],
    );
  }
}
